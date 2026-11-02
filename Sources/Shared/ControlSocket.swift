import Foundation

/// Local control channel between the app and the `fenestra` command-line tool.
///
/// Protocol: the client connects to a Unix domain socket, writes one JSON request terminated by a
/// newline, `{"command": "...", "arguments": {...}}`, and reads one JSON reply terminated by a
/// newline, `{"ok": true, "result": ...}` or `{"ok": false, "error": "..."}`.
enum ControlSocket {
    static let appBundleIdentifier = "com.florentamaridon.Fenestra"

    /// `~/Library/Application Support/Fenestra/control.sock`, readable by the user only.
    static var url: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Fenestra", isDirectory: true)
            .appendingPathComponent("control.sock", isDirectory: false)
    }

    /// Largest request or reply accepted, in bytes.
    static let maxMessageSize = 1 << 20

    /// Fills a `sockaddr_un` for `path`; nil if the path is too long for it.
    static func address(for path: String) -> sockaddr_un? {
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let bytes = Array(path.utf8)
        let capacity = MemoryLayout.size(ofValue: address.sun_path)
        guard bytes.count < capacity else { return nil }
        withUnsafeMutableBytes(of: &address.sun_path) { buffer in
            buffer.copyBytes(from: bytes)
            buffer[bytes.count] = 0
        }
        return address
    }

    /// Reads from `fd` until a newline, end of file or `maxMessageSize`. Returns the bytes before the newline.
    static func readLine(from fd: Int32) -> Data? {
        var data = Data()
        var chunk = [UInt8](repeating: 0, count: 4096)
        while data.count < maxMessageSize {
            let count = read(fd, &chunk, chunk.count)
            if count <= 0 { break }
            if let newline = chunk[0..<count].firstIndex(of: UInt8(ascii: "\n")) {
                data.append(contentsOf: chunk[0..<newline])
                return data
            }
            data.append(contentsOf: chunk[0..<count])
        }
        return data.isEmpty ? nil : data
    }

    /// Writes all of `data` followed by a newline.
    @discardableResult
    static func writeLine(_ data: Data, to fd: Int32) -> Bool {
        var payload = data
        payload.append(UInt8(ascii: "\n"))
        return payload.withUnsafeBytes { buffer -> Bool in
            var offset = 0
            while offset < buffer.count {
                let written = write(fd, buffer.baseAddress! + offset, buffer.count - offset)
                if written <= 0 { return false }
                offset += written
            }
            return true
        }
    }
}
