import SwiftUI

struct SessionThumbnailCard: View {
    let session: EditSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Thumbnail
            ZStack {
                Color(.secondarySystemBackground)
                if let data = session.thumbnailData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text(session.recipeName)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Text(session.modifiedAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 2)
        }
    }
}
