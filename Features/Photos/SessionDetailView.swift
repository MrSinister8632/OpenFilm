import SwiftUI
import Photos

struct SessionDetailView: View {
    @Bindable var session: EditSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var sourceImage: CIImage?
    @State private var loadError: String?
    @State private var showEditor = false
    @State private var showExport = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Preview
                imagePreview
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4, y: 2)
                    .padding(.horizontal)

                // Metadata
                VStack(spacing: 12) {
                    metaRow(label: "Recipe",    value: session.recipeName)
                    metaRow(label: "Edited",    value: session.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                    metaRow(label: "Fingerprint", value: RecipeFingerprint.generate(for: session.recipeSnapshot))
                }
                .padding(.horizontal)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // Actions
                VStack(spacing: 12) {
                    if sourceImage != nil {
                        Button {
                            showEditor = true
                        } label: {
                            Label("Edit Again", systemImage: "slider.horizontal.3")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                                .font(.headline)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showExport = true
                        } label: {
                            Label("Export Image", systemImage: "arrow.down.to.line")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle(session.recipeName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadSourceImage)
        .sheet(isPresented: $showEditor) {
            if let img = sourceImage {
                EditorView(
                    sourceImage: img,
                    sourcePhotoID: session.sourcePhotoID
                ) { newSession in
                    // Update existing session in place
                    session.applyRecipe(newSession.recipeSnapshot)
                    if let thumb = newSession.thumbnailData {
                        session.thumbnailData = thumb
                    }
                }
            }
        }
        .sheet(isPresented: $showExport) {
            if let img = sourceImage {
                ExportView(sourceImage: img, recipe: session.recipeSnapshot)
            }
        }
    }

    // MARK: - Image preview

    private var imagePreview: some View {
        ZStack {
            Color(.secondarySystemBackground)
            if let thumb = session.thumbnailData,
               let uiImg = UIImage(data: thumb) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No preview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Load source

    private func loadSourceImage() {
        let assetID = session.sourcePhotoID
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else { return }
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
            guard let asset = result.firstObject else { return }

            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false
            options.isSynchronous = false

            PHImageManager.default().requestImageDataAndOrientation(
                for: asset, options: options
            ) { data, _, _, _ in
                DispatchQueue.main.async {
                    if let data, let ci = CIImage(data: data) {
                        self.sourceImage = ci
                    }
                }
            }
        }
    }
}
