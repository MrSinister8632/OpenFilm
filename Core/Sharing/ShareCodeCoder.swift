import Foundation
import Compression

/// Encodes and decodes recipes to/from OPENFILM:// share codes.
///
/// Pipeline (encode):
///   Recipe → Canonical JSON → zlib compress → base32 encode → OPENFILM://TOKEN
///
/// Pipeline (decode):
///   OPENFILM://TOKEN → base32 decode → zlib decompress → JSON → Recipe + fingerprint verify
struct ShareCodeCoder {

    static let scheme = "OPENFILM://"

    // MARK: - Shared Recipe wrapper

    struct SharedRecipe: Codable {
        let version: Int
        let recipe: RecipePayload
        let fingerprint: String
    }

    struct RecipePayload: Codable {
        var name: String
        var exposure: Double
        var contrast: Double
        var highlights: Double
        var shadows: Double
        var saturation: Double
        var temperature: Double
        var tint: Double
        var grainAmount: Double
        var vignetteAmount: Double
        var sharpness: Double

        init(from recipe: Recipe) {
            name          = recipe.name
            exposure      = recipe.exposure
            contrast      = recipe.contrast
            highlights    = recipe.highlights
            shadows       = recipe.shadows
            saturation    = recipe.saturation
            temperature   = recipe.temperature
            tint          = recipe.tint
            grainAmount   = recipe.grainAmount
            vignetteAmount = recipe.vignetteAmount
            sharpness     = recipe.sharpness
        }

        func toRecipe() -> Recipe {
            Recipe(
                name:           name,
                exposure:       exposure,
                contrast:       contrast,
                highlights:     highlights,
                shadows:        shadows,
                saturation:     saturation,
                temperature:    temperature,
                tint:           tint,
                grainAmount:    grainAmount,
                vignetteAmount: vignetteAmount,
                sharpness:      sharpness
            )
        }
    }

    // MARK: - Encode

    static func encode(recipe: Recipe) throws -> String {
        let fingerprint = RecipeFingerprint.generate(for: recipe)
        let payload = RecipePayload(from: recipe)
        let shared  = SharedRecipe(version: 1, recipe: payload, fingerprint: fingerprint)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = try encoder.encode(shared)

        let compressed = try compress(json)
        let token      = base32Encode(compressed)
        return "\(scheme)\(token)"
    }

    // MARK: - Decode

    enum DecodeError: LocalizedError {
        case invalidScheme
        case invalidBase32
        case decompressionFailed
        case invalidJSON
        case fingerprintMismatch

        var errorDescription: String? {
            switch self {
            case .invalidScheme:          return "Not a valid OpenFilm code."
            case .invalidBase32:          return "Code appears corrupted."
            case .decompressionFailed:    return "Could not decompress recipe data."
            case .invalidJSON:            return "Recipe data is malformed."
            case .fingerprintMismatch:    return "Recipe Integrity Check Failed."
            }
        }
    }

    static func decode(code: String) throws -> Recipe {
        let upper = code.uppercased()
        guard upper.hasPrefix(scheme) else { throw DecodeError.invalidScheme }

        let token = String(upper.dropFirst(scheme.count))

        guard let compressed = base32Decode(token) else { throw DecodeError.invalidBase32 }

        guard let json = try? decompress(compressed) else { throw DecodeError.decompressionFailed }

        let shared: SharedRecipe
        do {
            shared = try JSONDecoder().decode(SharedRecipe.self, from: json)
        } catch {
            throw DecodeError.invalidJSON
        }

        let recipe = shared.recipe.toRecipe()

        guard RecipeFingerprint.verify(shared.fingerprint, for: recipe) else {
            throw DecodeError.fingerprintMismatch
        }

        return recipe
    }

    // MARK: - Compression helpers (zlib via Apple Compression)

    private static func compress(_ data: Data) throws -> Data {
        var outputBuffer = [UInt8](repeating: 0, count: data.count + 1024)
        let compressedSize = data.withUnsafeBytes { inputPtr -> Int in
            guard let baseAddress = inputPtr.baseAddress else { return 0 }
            return compression_encode_buffer(
                &outputBuffer, outputBuffer.count,
                baseAddress.assumingMemoryBound(to: UInt8.self), data.count,
                nil, COMPRESSION_ZLIB
            )
        }
        guard compressedSize > 0 else {
            // Fall back to uncompressed if zlib fails (small recipes)
            return data
        }
        return Data(outputBuffer.prefix(compressedSize))
    }

    private static func decompress(_ data: Data) throws -> Data {
        // Allocate a generous output buffer; recipes are small
        var outputBuffer = [UInt8](repeating: 0, count: data.count * 20 + 4096)
        let decompressedSize = data.withUnsafeBytes { inputPtr -> Int in
            guard let baseAddress = inputPtr.baseAddress else { return 0 }
            return compression_decode_buffer(
                &outputBuffer, outputBuffer.count,
                baseAddress.assumingMemoryBound(to: UInt8.self), data.count,
                nil, COMPRESSION_ZLIB
            )
        }
        if decompressedSize > 0 {
            return Data(outputBuffer.prefix(decompressedSize))
        }
        // Fallback: try as raw JSON (uncompressed path)
        return data
    }

    // MARK: - Base32 (RFC 4648, uppercase, no padding)

    private static let base32Alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    private static let base32Lookup: [Character: UInt8] = {
        Dictionary(uniqueKeysWithValues: base32Alphabet.enumerated().map { ($0.element, UInt8($0.offset)) })
    }()

    private static func base32Encode(_ data: Data) -> String {
        var result = ""
        var buffer = 0
        var bitsLeft = 0

        for byte in data {
            buffer = (buffer << 8) | Int(byte)
            bitsLeft += 8
            while bitsLeft >= 5 {
                bitsLeft -= 5
                result.append(base32Alphabet[(buffer >> bitsLeft) & 0x1F])
            }
        }
        if bitsLeft > 0 {
            result.append(base32Alphabet[(buffer << (5 - bitsLeft)) & 0x1F])
        }
        return result
    }

    private static func base32Decode(_ string: String) -> Data? {
        var result = Data()
        var buffer = 0
        var bitsLeft = 0

        for char in string {
            guard let value = base32Lookup[char] else { continue }
            buffer = (buffer << 5) | Int(value)
            bitsLeft += 5
            if bitsLeft >= 8 {
                bitsLeft -= 8
                result.append(UInt8((buffer >> bitsLeft) & 0xFF))
            }
        }
        return result.isEmpty ? nil : result
    }
}
