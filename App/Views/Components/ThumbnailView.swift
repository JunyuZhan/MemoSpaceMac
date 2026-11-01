import SwiftUI
import MemoSpaceKit

struct ThumbnailView: View {
    let item: RemoteItem
    @EnvironmentObject private var model: AppModel
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .quaternaryLabelColor).opacity(0.25))
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: item.kind.symbolName)
                    .font(.system(size: 36))
                    .foregroundStyle(item.kind.tint)
            }
        }
        .task(id: item.id) {
            guard item.kind == .image || item.kind == .pdf else { return }
            if let url = await model.thumbnailURL(for: item) {
                image = NSImage(contentsOf: url)
            }
        }
    }
}
