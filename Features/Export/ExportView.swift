import SwiftUI
import Photos

struct ExportView: View {
    let sourceImage: CIImage
    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss
    @AppStorage("exportFormat")  private var exportFormat:  ExportFormat  = .jpeg
    @AppStorage("exportQuality") private var exportQuality: ExportQuality = .full

    @State private var exporting = false
    @State private var result: ExportResult?

    enum ExportResult {
        case success
        case failure(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.label).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Quality") {
                    ForEach(ExportQuality.allCases) { quality in
                        QualityRow(quality: quality, isSelected: exportQuality == quality)
                            .contentShape(Rectangle())
                            .onTapGesture { exportQuality = quality }
                    }
                }

                Section {
                    Button(action: exportImage) {
                        HStack {
                            Spacer()
                            if exporting {
                                ProgressView()
                            } else {
                                Label("Save to Photos", systemImage: "arrow.down.to.line")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .disabled(exporting)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(alertTitle, isPresented: .constant(result != nil)) {
                Button("OK") {
                    if case .success = result { dismiss() }
                    result = nil
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var alertTitle: String {
        switch result {
        case .success: return "Saved"
        case .failure: return "Export Failed"
        case nil:      return ""
        }
    }

    private var alertMessage: String {
        switch result {
        case .success:           return "Your edited photo has been saved to your Photos library."
        case .failure(let msg):  return msg
        case nil:                return ""
        }
    }

    private func exportImage() {
        exporting = true
        let maxDim: CGFloat? = exportQuality.maxDimension
        let format = exportFormat
        let recipe = recipe
        let source = sourceImage

        Task.detached(priority: .userInitiated) {
            guard let rendered = ImageProcessor.shared.render(
                image: source,
                recipe: recipe,
                maxDimension: maxDim
            ) else {
                await finishWith(.failure("Could not render image."))
                return
            }

            let imageData: Data?
            switch format {
            case .jpeg:
                imageData = rendered.jpegData(compressionQuality: 0.92)
            case .heic:
                imageData = rendered.heicData()
            }

            guard let data = imageData else {
                await finishWith(.failure("Could not encode image in selected format."))
                return
            }

            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: nil)
                }
                await finishWith(.success)
            } catch {
                await finishWith(.failure(error.localizedDescription))
            }
        }
    }

    @MainActor
    private func finishWith(_ r: ExportResult) {
        result = r
        exporting = false
    }
}

// MARK: - QualityRow

private struct QualityRow: View {
    let quality: ExportQuality
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(quality.label)
                    .font(.body)
                Text(quality.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

// MARK: - HEIC helper

extension UIImage {
    func heicData(compressionQuality: CGFloat = 0.9) -> Data? {
        guard let mutableData = NSMutableData() as CFMutableData?,
              let destination = CGImageDestinationCreateWithData(
                  mutableData, "public.heic" as CFString, 1, nil
              ) else { return nil }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        guard let cgImage else { return nil }
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}
