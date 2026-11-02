import Foundation
import os

private let log = Logger(subsystem: "com.florentamaridon.Fenestra", category: "commands")

/// Listens on the control socket (see `ControlSocket`) and hands each request to the command service.
/// Socket I/O runs on a background queue; commands run on the main actor.
final class ControlServer: @unchecked Sendable {
    typealias Handler = @Sendable (Data) async -> Data

    private let queue = DispatchQueue(label: "com.florentamaridon.Fenestra.control")
    private let handler: Handler
    // Only touched on `queue`.
    private var listener: Int32 = -1
    private var source: DispatchSourceRead?

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func start() {
        queue.async { self.open() }
    }

    func stop() {
        queue.async { self.close() }
    }

    private func open() {
        guard listener < 0 else { return }
        let url = ControlSocket.url
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        } catch {
            log.error("control folder: \(error.localizedDescription, privacy: .public)")
            return
        }
        guard var address = ControlSocket.address(for: url.path) else {
            log.error("control socket path too long")
            return
        }
        unlink(url.path)
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return }
        // Created with no access for others before it is visible.
        let previousMask = umask(0o077)
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        umask(previousMask)
        guard bound == 0, listen(fd, 8) == 0 else {
            log.error("control socket bind/listen failed: \(errno)")
            Darwin.close(fd)
            return
        }
        listener = fd
        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        source.setEventHandler { [weak self] in self?.accept() }
        source.resume()
        self.source = source
        log.info("control socket ready")
    }

    private func close() {
        source?.cancel()
        source = nil
        if listener >= 0 {
            Darwin.close(listener)
            listener = -1
            unlink(ControlSocket.url.path)
        }
    }

    private func accept() {
        let client = Darwin.accept(listener, nil, nil)
        guard client >= 0 else { return }
        var noSigPipe: Int32 = 1
        setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))
        var timeout = timeval(tv_sec: 5, tv_usec: 0)
        setsockopt(client, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        let handler = self.handler
        let queue = self.queue
        queue.async {
            guard let request = ControlSocket.readLine(from: client) else {
                Darwin.close(client)
                return
            }
            Task {
                let reply = await handler(request)
                queue.async {
                    ControlSocket.writeLine(reply, to: client)
                    Darwin.close(client)
                }
            }
        }
    }
}
