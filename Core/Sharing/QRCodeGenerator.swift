import CoreImage.CIFilterBuiltins
import UIKit

struct QRCodeGenerator {
    /// Generates a UIImage QR code for the given string at the given point size.
    /// Returns nil if generation fails.
    static func generate(from string: String, size: CGFloat = 200) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"

        guard let ciImage = filter.outputImage else { return nil }

        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}
