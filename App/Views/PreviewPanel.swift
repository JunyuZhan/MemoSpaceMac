import SwiftUI
import AppKit
import AVKit
import PDFKit
import QuickLookUI
import MemoSpaceKit

struct PreviewPanel: View {
    let item: RemoteItem
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var url: URL?
    @State private var isLoading = true
    @State private var showLargeFileAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: item.kind.symbolName)
                    .foregroundStyle(item.kind.tint)
                Text(item.name).font(.headline).lineLimit(1)
                Spacer()
                Button("关闭") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
            Divider()
            ZStack {
                if isLoading {
                    ProgressView("正在下载…")
                } else if let url {
                    preview(url)
                } else {
                    ContentUnavailableView("无法预览", systemImage: "exclamationmark.triangle")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 720, minHeight: 520)
        .task {
            if item.size > 2_000_000_000 {
                showLargeFileAlert = true
            } else {
                await load()
            }
        }
        .alert("文件较大", isPresented: $showLargeFileAlert) {
            Button("下载预览") { Task { await load() } }
            Button("取消", role: .cancel) { dismiss() }
        } message: {
            Text("该文件约 \(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))，需要完整下载后才能预览。")
        }
    }

    @ViewBuilder
    private func preview(_ url: URL) -> some View {
        switch item.kind {
        case .image:
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            } else {
                Text("无法加载图片")
            }
        case .pdf:
            PDFKitView(url: url)
        case .video, .audio:
            VideoPlayerView(url: url)
        case .text:
            ScrollView {
                Text((try? String(contentsOf: url, encoding: .utf8)) ?? "无法读取文本")
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        default:
            QuickLookView(url: url)
        }
    }

    private func load() async {
        isLoading = true
        url = await model.previewURL(for: item)
        isLoading = false
    }
}

struct PDFKitView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(url: url)
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {}
}

struct VideoPlayerView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .floating
        view.player = AVPlayer(url: url)
        view.player?.play()
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {}
}

struct QuickLookView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> QLPreviewView {
        let view: QLPreviewView = QLPreviewView(frame: .zero, style: .normal)
        view.previewItem = url as NSURL
        return view
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        nsView.previewItem = url as NSURL
    }
}
