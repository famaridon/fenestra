import Foundation
import Harmonize
import SwiftParser
import SwiftSyntax
import Testing

/// Clean architecture rules of `Sources/Fenestra` (see ARCHITECTURE.md, "Couches").
///
/// Every file sits in `<Feature>/<Layer>/` (or `App/`, the composition root). A layer may only use the
/// layers listed in `Rules.allowedLayers`; another feature only through its Domain and Application;
/// `Kernel` (shared by every feature) depends on no feature.
struct ArchitectureTests {
    enum Layer: String, CaseIterable {
        case domain = "Domain"
        case application = "Application"
        case infrastructure = "Infrastructure"
        case presentation = "Presentation"
        case app = "App"
    }

    struct Location: Hashable, CustomStringConvertible {
        let feature: String
        let layer: Layer
        var description: String { layer == .app ? "App" : "\(feature)/\(layer.rawValue)" }
    }

    enum Rules {
        static let root = "Sources/Fenestra"
        static let kernel = "Kernel"

        /// Domain and Application stay pure Swift: no AppKit, Accessibility, ScreenCaptureKit, Carbon…
        static let allowedImports: [Layer: Set<String>] = [
            .domain: ["Foundation", "CoreGraphics"],
            .application: ["Foundation", "CoreGraphics", "Observation", "os"],
        ]

        static let allowedLayers: [Layer: Set<Layer>] = [
            .domain: [.domain],
            .application: [.domain, .application],
            .infrastructure: [.domain, .application, .infrastructure],
            .presentation: [.domain, .application, .presentation],
            .app: Set(Layer.allCases),
        ]

        static func allows(_ from: Location, toUse to: Location) -> Bool {
            guard allowedLayers[from.layer, default: []].contains(to.layer) else { return false }
            if from.layer == .app || to.feature == from.feature || to.feature == kernel { return true }
            if from.feature == kernel { return false }
            return to.layer == .domain || to.layer == .application
        }
    }

    // MARK: Scope

    /// Harmonize caches the parsed files between calls.
    private static var sources: [SwiftSourceCode] { Harmonize.productionCode().on(Rules.root).sources() }

    /// `Sources/Fenestra/<Feature>/<Layer>/…` or `Sources/Fenestra/App/…`; nil for any other place.
    static func location(of source: SwiftSourceCode) -> Location? {
        guard let path = source.filePath?.standardizedFileURL.path,
              let range = path.range(of: "/\(Rules.root)/") else { return nil }
        let components = path[range.upperBound...].split(separator: "/").map(String.init)
        guard components.count >= 2 else { return nil }
        if components[0] == Layer.app.rawValue { return Location(feature: "App", layer: .app) }
        guard components.count >= 3, let layer = Layer(rawValue: components[1]), layer != .app else { return nil }
        return Location(feature: components[0], layer: layer)
    }

    private static func sources(in layers: Set<Layer>) -> [SwiftSourceCode] {
        sources.filter { location(of: $0).map { layers.contains($0.layer) } ?? false }
    }

    // MARK: Rules

    @Test func scopeIsNotEmpty() {
        #expect(Self.sources.count > 40)
    }

    @Test func everyFileSitsInAFeatureLayerOrInApp() {
        Self.sources.assertTrue(message: "move the file to <Feature>/<Domain|Application|Infrastructure|Presentation>/ or App/") {
            Self.location(of: $0) != nil
        }
    }

    @Test func domainImportsOnlyFoundationAndCoreGraphics() {
        let allowed = Rules.allowedImports[.domain]!
        Self.sources(in: [.domain]).assertTrue(message: "Domain may import only \(allowed.sorted())") {
            $0.imports().allSatisfy { allowed.contains($0.name) }
        }
    }

    @Test func applicationImportsNoUIOrSystemFramework() {
        let allowed = Rules.allowedImports[.application]!
        Self.sources(in: [.application]).assertTrue(message: "Application may import only \(allowed.sorted())") {
            $0.imports().allSatisfy { allowed.contains($0.name) }
        }
    }

    @Test func domainHoldsValueTypesOnly() {
        let domain = Self.sources(in: [.domain])
        domain.flatMap { $0.classes() }.assertEmpty(message: "Domain types are structs and enums")
        domain.flatMap { $0.actors() }.assertEmpty(message: "Domain types are structs and enums")
    }

    @Test func layersOnlyUseTheTypesTheyMayDependOn() {
        let declared = Self.declaredTypes()
        var violations: [String] = []
        for source in Self.sources {
            guard let from = Self.location(of: source), from.layer != .app, let path = source.filePath else { continue }
            let tree = Parser.parse(source: source.source)
            let converter = SourceLocationConverter(fileName: path.path, tree: tree)
            var reported = Set<String>()
            for token in tree.tokens(viewMode: .sourceAccurate) {
                guard case .identifier(let name) = token.tokenKind, let owners = declared[name],
                      !owners.contains(where: { Rules.allows(from, toUse: $0) }),
                      reported.insert(name).inserted else { continue }
                let line = token.startLocation(converter: converter).line
                let owner = owners.map(\.description).sorted().joined(separator: ", ")
                violations.append("\(path.lastPathComponent):\(line): \(from) uses \(name) from \(owner)")
            }
        }
        #expect(violations.isEmpty, Comment(rawValue: "Forbidden dependencies:\n" + violations.joined(separator: "\n")))
    }

    /// Name of every type declared in the production code -> where it is declared.
    private static func declaredTypes() -> [String: Set<Location>] {
        var result: [String: Set<Location>] = [:]
        for source in sources {
            guard let location = location(of: source) else { continue }
            let names = source.classes().map(\.name) + source.structs().map(\.name) + source.enums().map(\.name)
                + source.protocols().map(\.name) + source.actors().map(\.name)
            for name in names { result[name, default: []].insert(location) }
        }
        return result
    }
}
