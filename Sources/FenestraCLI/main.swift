import Foundation

// `fenestra`: command-line access to the running Fenestra app, and an MCP server for AI agents.
//
//   fenestra mcp                 MCP server over stdio (Claude Desktop, Claude Code, Cursor…)
//   fenestra displays            list the displays
//   fenestra windows             list the windows Fenestra can move
//   fenestra layout '<json>'     apply a layout (JSON argument, or "-" to read it from stdin)

let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("fenestra: \(message)\n".utf8))
    exit(1)
}

// MARK: Control socket client

enum ClientError: Error, CustomStringConvertible {
    case notRunning, io, badReply
    var description: String {
        switch self {
        case .notRunning: "Fenestra is not running and could not be started"
        case .io: "lost the connection to Fenestra"
        case .badReply: "unexpected reply from Fenestra"
        }
    }
}

func connectToApp() -> Int32? {
    guard var address = ControlSocket.address(for: ControlSocket.url.path) else { return nil }
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else { return nil }
    let result = withUnsafePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
        }
    }
    if result != 0 {
        close(fd)
        return nil
    }
    var noSigPipe: Int32 = 1
    setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))
    // Launching apps for a layout can take a while.
    var timeout = timeval(tv_sec: 30, tv_usec: 0)
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
    return fd
}

/// Connects to the app, starting it in the background if needed.
func connectOrLaunch() throws -> Int32 {
    if let fd = connectToApp() { return fd }
    let open = Process()
    open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    open.arguments = ["-g", "-b", ControlSocket.appBundleIdentifier]
    try? open.run()
    open.waitUntilExit()
    for _ in 0..<40 {
        usleep(250_000)
        if let fd = connectToApp() { return fd }
    }
    throw ClientError.notRunning
}

/// Sends a command and returns the decoded reply: `(ok, result or error message)`.
func send(_ command: String, arguments: Any) throws -> (ok: Bool, payload: Any) {
    let fd = try connectOrLaunch()
    defer { close(fd) }
    let request = try JSONSerialization.data(withJSONObject: ["command": command, "arguments": arguments])
    guard ControlSocket.writeLine(request, to: fd), let reply = ControlSocket.readLine(from: fd) else {
        throw ClientError.io
    }
    guard let object = try? JSONSerialization.jsonObject(with: reply) as? [String: Any],
          let ok = object["ok"] as? Bool else { throw ClientError.badReply }
    return ok ? (true, object["result"] ?? NSNull()) : (false, object["error"] as? String ?? "unknown error")
}

func pretty(_ value: Any) -> String {
    guard JSONSerialization.isValidJSONObject(value),
          let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]) else {
        return String(describing: value)
    }
    return String(decoding: data, as: UTF8.self)
}

// MARK: MCP server

let zoneNames = [
    "leftHalf", "rightHalf", "topHalf", "bottomHalf",
    "topLeft", "topRight", "bottomLeft", "bottomRight",
    "maximize", "leftThird", "centerThird", "rightThird", "leftTwoThirds", "rightTwoThirds",
]

let emptySchema: [String: Any] = ["type": "object", "properties": [String: Any]()]

let tools: [[String: Any]] = [
    [
        "name": "list_displays",
        "title": "List displays",
        "description": """
            Lists the connected displays in reading order (left to right, then top to bottom). \
            "index" is what apply_layout accepts as "display". Frames are in points, origin at the top left \
            of the primary display.
            """,
        "inputSchema": emptySchema,
        "annotations": ["readOnlyHint": true],
    ],
    [
        "name": "list_windows",
        "title": "List windows",
        "description": """
            Lists the windows Fenestra can move (standard, not minimized, not full screen, not excluded), \
            front-most first within each app, with their app name, bundle identifier, title, display index, \
            frame and, if snapped, zone. Call it before apply_layout to learn the exact app names.
            """,
        "inputSchema": emptySchema,
        "annotations": ["readOnlyHint": true],
    ],
    [
        "name": "apply_layout",
        "title": "Apply a window layout",
        "description": """
            Arranges several windows in one call. Each placement picks a window by app (name or bundle \
            identifier, case-insensitive) and optionally by a part of its title, then puts it on a display, \
            either in a named zone or in a custom rect. Each window is used at most once: to place two windows \
            of the same app, list the app twice (front-most window first) or tell them apart with "title". \
            Windows not mentioned are left where they are. The first placement ends up in front. \
            Returns the windows placed and, for each placement that failed, why.
            """,
        "inputSchema": [
            "type": "object",
            "properties": [
                "placements": [
                    "type": "array",
                    "minItems": 1,
                    "items": [
                        "type": "object",
                        "properties": [
                            "app": ["type": "string", "description": "App name (\"Safari\") or bundle identifier (\"com.apple.Safari\")."],
                            "title": ["type": "string", "description": "Part of the window title, case-insensitive."],
                            "display": [
                                "type": "string",
                                "description": """
                                    Display: "primary" (default, the one with the menu bar), an index from \
                                    list_displays ("1", "2"…), "left", "right", "top" or "bottom".
                                    """,
                            ],
                            "zone": ["type": "string", "enum": zoneNames, "description": "Named zone. Give a zone or a rect, not both."],
                            "rect": [
                                "type": "object",
                                "description": "Custom area in fractions (0 to 1) of the display's usable area, origin top left. Example: left 60% = {x:0, y:0, width:0.6, height:1}.",
                                "properties": [
                                    "x": ["type": "number", "minimum": 0, "maximum": 1],
                                    "y": ["type": "number", "minimum": 0, "maximum": 1],
                                    "width": ["type": "number", "exclusiveMinimum": 0, "maximum": 1],
                                    "height": ["type": "number", "exclusiveMinimum": 0, "maximum": 1],
                                ],
                                "required": ["x", "y", "width", "height"],
                            ],
                        ],
                        "required": ["app"],
                    ],
                ],
                "launch_apps": [
                    "type": "boolean",
                    "description": "Open the apps that have no matching window and wait for their windows (up to 10 s). Default false.",
                ],
            ],
            "required": ["placements"],
        ],
        "annotations": ["readOnlyHint": false, "destructiveHint": false, "idempotentHint": true],
    ],
]

let supportedProtocolVersions = ["2025-06-18", "2025-03-26", "2024-11-05"]

func writeMessage(_ message: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: message) else { return }
    FileHandle.standardOutput.write(data + Data("\n".utf8))
}

func respond(_ id: Any, result: Any) {
    writeMessage(["jsonrpc": "2.0", "id": id, "result": result])
}

func respond(_ id: Any, errorCode: Int, message: String) {
    writeMessage(["jsonrpc": "2.0", "id": id, "error": ["code": errorCode, "message": message]])
}

@MainActor func callTool(_ params: [String: Any]) -> [String: Any] {
    let name = params["name"] as? String ?? ""
    let arguments = params["arguments"] ?? [String: Any]()
    func text(_ value: String, isError: Bool) -> [String: Any] {
        ["content": [["type": "text", "text": value]], "isError": isError]
    }
    guard tools.contains(where: { $0["name"] as? String == name }) else {
        return text("Unknown tool \(name)", isError: true)
    }
    do {
        let reply = try send(name, arguments: arguments)
        return reply.ok ? text(pretty(reply.payload), isError: false) : text("\(reply.payload)", isError: true)
    } catch {
        return text(String(describing: error), isError: true)
    }
}

@MainActor func runMCPServer() -> Never {
    while let line = readLine(strippingNewline: true) {
        guard !line.isEmpty else { continue }
        guard let message = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any] else {
            writeMessage(["jsonrpc": "2.0", "id": NSNull(), "error": ["code": -32700, "message": "Parse error"]])
            continue
        }
        let method = message["method"] as? String ?? ""
        let params = message["params"] as? [String: Any] ?? [:]
        // Notifications (no id) and replies to our own requests need no answer.
        guard let id = message["id"], !method.isEmpty else { continue }
        switch method {
        case "initialize":
            let requested = params["protocolVersion"] as? String ?? ""
            respond(id, result: [
                "protocolVersion": supportedProtocolVersions.contains(requested) ? requested : supportedProtocolVersions[0],
                "capabilities": ["tools": ["listChanged": false]],
                "serverInfo": ["name": "fenestra", "title": "Fenestra", "version": version],
                "instructions": """
                    Fenestra arranges the user's macOS windows. To set up a workspace, call list_windows \
                    (and list_displays with several displays), then a single apply_layout with every window.
                    """,
            ])
        case "ping":
            respond(id, result: [String: Any]())
        case "tools/list":
            respond(id, result: ["tools": tools])
        case "tools/call":
            respond(id, result: callTool(params))
        default:
            respond(id, errorCode: -32601, message: "Method not found: \(method)")
        }
    }
    exit(0)
}

// MARK: Command line

func runCommand(_ command: String, arguments: Any) -> Never {
    do {
        let reply = try send(command, arguments: arguments)
        guard reply.ok else { fail("\(reply.payload)") }
        print(pretty(reply.payload))
        exit(0)
    } catch {
        fail(String(describing: error))
    }
}

let usage = """
    usage: fenestra mcp
           fenestra displays
           fenestra windows
           fenestra layout '<json>' | -

    layout JSON: {"placements": [{"app": "Xcode", "zone": "leftTwoThirds"},
                                 {"app": "Safari", "display": "2", "rect": {"x": 0, "y": 0, "width": 0.5, "height": 1}}],
                  "launch_apps": true}
    """

let args = Array(CommandLine.arguments.dropFirst())
switch args.first {
case "mcp":
    runMCPServer()
case "displays":
    runCommand("list_displays", arguments: [String: Any]())
case "windows":
    runCommand("list_windows", arguments: [String: Any]())
case "layout":
    guard args.count == 2 else { fail("layout takes one JSON argument, or - for stdin\n\(usage)") }
    let data = args[1] == "-" ? FileHandle.standardInput.readDataToEndOfFile() : Data(args[1].utf8)
    guard let spec = try? JSONSerialization.jsonObject(with: data) else { fail("layout: invalid JSON") }
    runCommand("apply_layout", arguments: spec)
case "-h", "--help", "help":
    print(usage)
case "--version":
    print(version)
default:
    fail("unknown command\n\(usage)")
}
