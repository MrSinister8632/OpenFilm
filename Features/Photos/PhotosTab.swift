import SwiftUI
import SwiftData
import PhotosUI

struct PhotosTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EditSession.modifiedAt, order: .reverse) private var sessions: [EditSession]

    @State private var showPicker   = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var pendingImage: CIImage?
    @State private var pendingAssetID: String?
    @State private var showEditor   = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    importButton

                    if !sessions.isEmpty {
                        recentEditsSection
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("Photos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Import photo")
                }
            }
            .photosPicker(
                isPresented: $showPicker,
                selection: $pickerItem,
                matching: .images
            )
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                loadPickerItem(newItem)
            }
            .alert("Import Error", isPresented: .constant(importError != nil)) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
            .sheet(isPresented: $showEditor) {
                if let image = pendingImage {
                    EditorView(
                        sourceImage: image,
                        sourcePhotoID: pendingAssetID ?? UUID().uuidString,
                        onSave: { session in
                            modelContext.insert(session)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Subviews

    private var importButton: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Image(systemName: "photo.badge.plus")
                    .font(.title2)
                Text("Import Photo")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Import a photo from your library")
    }

    private var recentEditsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Edits")
                .font(.title3.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(sessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        SessionThumbnailCard(session: session)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(session)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No edits yet")
                .font(.title3.weight(.medium))
            Text("Import a photo and apply a recipe to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Load

    private func loadPickerItem(_ item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let data, let ciImage = CIImage(data: data) else {
                        importError = "Could not load image data."
                        return
                    }
                    pendingImage   = ciImage
                    pendingAssetID = item.itemIdentifier
                    showEditor     = true
                case .failure(let error):
                    importError = error.localizedDescription
                }
                pickerItem = nil
            }
        }
    }
}
