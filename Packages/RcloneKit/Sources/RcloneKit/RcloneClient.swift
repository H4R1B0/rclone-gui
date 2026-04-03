import Foundation
import CRclone

public final class RcloneClient: RcloneClientProtocol, @unchecked Sendable {
    private var isInitialized = false
    private let queue = DispatchQueue(label: "com.rclone-gui.rclone-rpc", qos: .userInitiated)

    public init() {}

    public func initialize() {
        queue.sync {
            guard !isInitialized else { return }
            RcloneInitialize()
            isInitialized = true
        }
    }

    public func finalize() {
        queue.sync {
            guard isInitialized else { return }
            RcloneFinalize()
            isInitialized = false
        }
    }

    public func call(_ method: String, params: [String: Any] = [:]) async throws -> [String: Any] {
        let initialized = queue.sync { isInitialized }
        guard initialized else {
            throw RcloneError.notInitialized
        }

        let jsonData = try JSONSerialization.data(withJSONObject: params)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw RcloneError.encodingFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let result = method.withCString { methodPtr in
                    jsonString.withCString { inputPtr in
                        RcloneRPC(
                            UnsafeMutablePointer(mutating: methodPtr),
                            UnsafeMutablePointer(mutating: inputPtr)
                        )
                    }
                }

                defer {
                    if result.Output != nil {
                        RcloneFreeString(result.Output)
                    }
                }

                guard let outputPtr = result.Output else {
                    continuation.resume(throwing: RcloneError.decodingFailed("Null RPC output"))
                    return
                }

                let outputStr = String(cString: outputPtr)

                guard let data = outputStr.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    continuation.resume(throwing: RcloneError.decodingFailed("Invalid RPC response"))
                    return
                }

                if result.Status != 200 {
                    let message = json["error"] as? String ?? "Unknown error"
                    continuation.resume(throwing: RcloneError.rpcFailed(
                        method: method, status: Int(result.Status), message: message
                    ))
                    return
                }

                continuation.resume(returning: json)
            }
        }
    }
}
