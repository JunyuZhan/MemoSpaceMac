import SwiftUI
import MemoSpaceKit

struct TransferCenterView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("传输中心").font(.headline)
                Spacer()
                Button("清除已完成") {
                    model.transferQueue.removeFinished()
                }
                Button("关闭") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
            Divider()

            if model.transferQueue.tasks.isEmpty {
                ContentUnavailableView("没有传输任务", systemImage: "arrow.up.arrow.down")
            } else {
                List(model.transferQueue.tasks) { task in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: task.direction == .upload
                                  ? "arrow.up.circle" : "arrow.down.circle")
                            Text(task.displayName).lineLimit(1)
                            Spacer()
                            Text(stateText(task))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: task.progress)
                        HStack {
                            Text("\(ByteCountFormatter.string(fromByteCount: task.transferredBytes, countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: task.totalBytes, countStyle: .file))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if task.state == .running || task.state == .queued {
                                Button("取消") {
                                    model.transferQueue.cancel(id: task.id)
                                }
                                .buttonStyle(.link)
                            } else if task.state.isFailed {
                                Button("重试") {
                                    model.transferQueue.retry(id: task.id)
                                }
                                .buttonStyle(.link)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(minWidth: 580, minHeight: 420)
    }

    private func stateText(_ task: TransferTask) -> String {
        switch task.state {
        case .queued: return "排队中"
        case .running: return "\(Int(task.progress * 100))%"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        case let .failed(message): return message
        }
    }
}
