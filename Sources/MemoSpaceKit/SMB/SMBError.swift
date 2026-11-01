import Foundation

public enum SMBError: Error, Equatable, LocalizedError {
    case authenticationFailed
    case shareNotFound(String)
    case permissionDenied
    case notFound(String)
    case nameConflict(String)
    case noSpace
    case timeout
    case connectionLost
    case invalidName(String)
    case unsupported(String)
    case cancelled
    case other(String)

    public var errorDescription: String? {
        switch self {
        case .authenticationFailed: return "用户名或密码错误"
        case let .shareNotFound(name): return "找不到共享「\(name)」"
        case .permissionDenied: return "没有权限执行此操作"
        case let .notFound(path): return path.isEmpty ? "找不到文件或文件夹" : "找不到「\(path)」"
        case let .nameConflict(name): return name.isEmpty ? "已存在同名文件" : "已存在同名文件「\(name)」"
        case .noSpace: return "本地磁盘空间不足"
        case .timeout: return "连接超时，请检查设备是否在线"
        case .connectionLost: return "与设备的连接已断开"
        case let .invalidName(name): return "文件名「\(name)」不合法"
        case let .unsupported(feature): return "设备不支持「\(feature)」"
        case .cancelled: return "操作已取消"
        case let .other(message): return message.isEmpty ? "发生未知错误" : message
        }
    }

    public static func map(_ error: Error, path: String = "") -> SMBError {
        if let error = error as? SMBError { return error }
        if let error = error as? RemotePathError {
            switch error {
            case let .traversal(value): return .invalidName(value)
            case let .invalidName(name): return .invalidName(name)
            case .invalidCharacter: return .invalidName(path)
            }
        }
        if let error = error as? POSIXError {
            switch error.code {
            case .EACCES, .EPERM:
                return .permissionDenied
            case .ENOENT:
                return .notFound(path)
            case .EEXIST:
                return .nameConflict(path)
            case .ENOSPC:
                return .noSpace
            case .ETIMEDOUT:
                return .timeout
            case .ECONNRESET, .ECONNABORTED, .ENOTCONN, .EPIPE,
                 .ENETDOWN, .ENETUNREACH, .EHOSTUNREACH, .ENETRESET:
                return .connectionLost
            case .ECANCELED:
                return .cancelled
            case .EINVAL, .ENAMETOOLONG:
                return .invalidName(path)
            case .EIO, .ENODEV:
                return .connectionLost
            default:
                return .other(error.localizedDescription)
            }
        }
        let nsError = error as NSError
        if nsError.domain == NSPOSIXErrorDomain,
           let code = POSIXErrorCode(rawValue: Int32(nsError.code)) {
            return map(POSIXError(code), path: path)
        }
        if nsError.domain == NSCocoaErrorDomain {
            switch nsError.code {
            case NSFileWriteOutOfSpaceError: return .noSpace
            case NSFileReadNoPermissionError, NSFileWriteNoPermissionError: return .permissionDenied
            case NSFileNoSuchFileError, NSFileReadNoSuchFileError: return .notFound(path)
            default: break
            }
        }
        return .other(nsError.localizedDescription)
    }
}
