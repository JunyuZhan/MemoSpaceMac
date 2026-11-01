import SwiftUI
import MemoSpaceKit

extension FileKind {
    var symbolName: String {
        switch self {
        case .folder: return "folder.fill"
        case .image: return "photo"
        case .video: return "film"
        case .audio: return "music.note"
        case .pdf: return "doc.richtext"
        case .text: return "doc.text"
        case .archive: return "archivebox"
        case .other: return "doc"
        }
    }

    var tint: Color {
        switch self {
        case .folder: return .blue
        case .image: return .green
        case .video: return .purple
        case .audio: return .orange
        case .pdf: return .red
        case .text: return .secondary
        case .archive: return .brown
        case .other: return .secondary
        }
    }
}
