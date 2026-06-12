import SwiftUI
import AVFoundation

struct ImportRecipeSheet: View {
    @Binding var isPresented: Bool
    let onImport: (String) -> Void

    @State private var codeText = ""
    @State private var showScanner = false
    @State private var cameraPermissionDenied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                // Icon
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)

                VStack(spacing: 8) {
                    Text("Import Recipe")
                        .font(.title2.weight(.semibold))
                    Text("Enter an OPENFILM:// code or scan a QR code to import a recipe.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Text entry
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recipe Code")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("OPENFILM://...", text: $codeText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                // Buttons
                VStack(spacing: 12) {
                    Button(action: importCode) {
                        Text("Import")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(codeText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(.systemFill)
                                : Color.accentColor)
                            .foregroundStyle(codeText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.secondary
                                : Color.white)
                            .cornerRadius(12)
                            .font(.headline)
                    }
                    .disabled(codeText.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button {
                        requestCameraAndScan()
                    } label: {
                        Label("Scan QR Code", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .font(.headline)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
            .sheet(isPresented: $showScanner) {
                QRScannerView { scanned in
                    showScanner = false
                    codeText = scanned
                    importCode()
                }
            }
            .alert("Camera Access Required", isPresented: $cameraPermissionDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please allow camera access in Settings to scan QR codes.")
            }
        }
    }

    private func importCode() {
        let trimmed = codeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onImport(trimmed)
        isPresented = false
    }

    private func requestCameraAndScan() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { showScanner = true }
                    else { cameraPermissionDenied = true }
                }
            }
        default:
            cameraPermissionDenied = true
        }
    }
}

// MARK: - QR Scanner

struct QRScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.onScan = onScan
        return vc
    }
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    private var captureSession: AVCaptureSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input  = try? AVCaptureDeviceInput(device: device) else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        captureSession = session
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }
        captureSession?.stopRunning()
        onScan?(value)
    }
}
