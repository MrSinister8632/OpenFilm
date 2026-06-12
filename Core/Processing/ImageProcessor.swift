import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Applies a Recipe to a CIImage using the ordered pipeline from the spec:
/// Exposure → Contrast → Highlights → Shadows → Temperature → Tint →
/// Saturation → Grain → Vignette → Sharpening
struct ImageProcessor {

    static let shared = ImageProcessor()
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - Public API

    func process(image: CIImage, recipe: Recipe) -> CIImage {
        var output = image

        output = applyExposure(output, ev: recipe.exposure)
        output = applyContrast(output, contrast: recipe.contrast)
        output = applyHighlightsShadows(output, highlights: recipe.highlights, shadows: recipe.shadows)
        output = applyTemperatureTint(output, temperature: recipe.temperature, tint: recipe.tint)
        output = applySaturation(output, saturation: recipe.saturation)

        if recipe.grainAmount > 0 {
            output = applyGrain(output, amount: recipe.grainAmount)
        }
        if recipe.vignetteAmount > 0 {
            output = applyVignette(output, amount: recipe.vignetteAmount)
        }
        if recipe.sharpness > 0 {
            output = applySharpen(output, amount: recipe.sharpness)
        }

        return output
    }

    /// Renders to UIImage at optional max dimension (for export quality settings).
    func render(image: CIImage, recipe: Recipe, maxDimension: CGFloat? = nil) -> UIImage? {
        var processed = process(image: image, recipe: recipe)

        if let max = maxDimension {
            let extent = processed.extent
            let scale = min(max / extent.width, max / extent.height, 1.0)
            if scale < 1.0 {
                processed = processed.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            }
        }

        guard let cgImage = context.createCGImage(processed, from: processed.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Pipeline steps

    private func applyExposure(_ image: CIImage, ev: Double) -> CIImage {
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = image
        filter.ev = Float(ev)
        return filter.outputImage ?? image
    }

    private func applyContrast(_ image: CIImage, contrast: Double) -> CIImage {
        // Map -1…+1 to a tone curve adjustment
        let filter = CIFilter.toneCurve()
        filter.inputImage = image
        let c = Float(contrast) * 0.15
        filter.point0 = CGPoint(x: 0,    y: max(0, Double(c)))
        filter.point1 = CGPoint(x: 0.25, y: Double(0.25 + c * 0.5))
        filter.point2 = CGPoint(x: 0.5,  y: 0.5)
        filter.point3 = CGPoint(x: 0.75, y: Double(0.75 - c * 0.5))
        filter.point4 = CGPoint(x: 1,    y: Double(min(1, 1 - c)))
        return filter.outputImage ?? image
    }

    private func applyHighlightsShadows(_ image: CIImage, highlights: Double, shadows: Double) -> CIImage {
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = image
        // CIHighlightShadowAdjust: highlights 0=max darken, 1=no change
        // shadows 0=no change, 1=max lighten — we normalise our -1…+1 range
        filter.highlightAmount = Float(1.0 + highlights)   // -1→0, 0→1, +1→2 clamped
        filter.shadowAmount    = Float(shadows)             // directly maps
        return filter.outputImage ?? image
    }

    private func applyTemperatureTint(_ image: CIImage, temperature: Double, tint: Double) -> CIImage {
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        // Neutral temperature is 6500K; our offset is ±400
        filter.neutral = CIVector(x: 6500 + temperature, y: 0)
        filter.targetNeutral = CIVector(x: 6500 + temperature, y: CGFloat(tint))
        return filter.outputImage ?? image
    }

    private func applySaturation(_ image: CIImage, saturation: Double) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = Float(1.0 + saturation)  // -1→0 (B&W), 0→1 (no change), +1→2
        filter.brightness = 0
        filter.contrast   = 1
        return filter.outputImage ?? image
    }

    private func applyGrain(_ image: CIImage, amount: Double) -> CIImage {
        // Generate random noise and blend over image
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator"),
              let noiseImage  = noiseFilter.outputImage else { return image }

        let blendFilter = CIFilter(name: "CISoftLightBlendMode")!
        blendFilter.setValue(
            noiseImage.cropped(to: image.extent)
                      .applyingFilter("CIColorMatrix", parameters: [
                          "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                          "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                          "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                          "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(amount * 0.4)),
                          "inputBiasVector": CIVector(x: CGFloat(amount * 0.1),
                                                      y: CGFloat(amount * 0.1),
                                                      z: CGFloat(amount * 0.1),
                                                      w: 0)
                      ]),
            forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        return blendFilter.outputImage ?? image
    }

    private func applyVignette(_ image: CIImage, amount: Double) -> CIImage {
        let filter = CIFilter.vignette()
        filter.inputImage = image
        filter.intensity  = Float(amount * 2.0)
        filter.radius     = Float(1.5 - amount * 0.5)
        return filter.outputImage ?? image
    }

    private func applySharpen(_ image: CIImage, amount: Double) -> CIImage {
        let filter = CIFilter.unsharpMask()
        filter.inputImage  = image
        filter.intensity   = Float(amount)
        filter.radius      = 2.5
        return filter.outputImage ?? image
    }
}
