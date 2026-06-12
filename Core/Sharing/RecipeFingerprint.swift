import CryptoKit
import Foundation

/// Generates and verifies recipe fingerprints.
/// Uses SHA256 of the canonical recipe string; takes the first 8 hex characters.
/// Format: 4E7A-82F1
/// Not intended as cryptographic security — used for integrity checking only.
struct RecipeFingerprint {

    /// Generates a display fingerprint (e.g. "4E7A-82F1") from a Recipe.
    static func generate(for recipe: Recipe) -> String {
        let canonical = recipe.canonicalString
        guard let data = canonical.data(using: .utf8) else { return "????-????" }

        let hash   = SHA256.hash(data: data)
        let hexFull = hash.compactMap { String(format: "%02X", $0) }.joined()
        let first8  = String(hexFull.prefix(8))

        let a = String(first8.prefix(4))
        let b = String(first8.suffix(4))
        return "\(a)-\(b)"
    }

    /// Verifies that a stored fingerprint matches a freshly generated one.
    static func verify(_ fingerprint: String, for recipe: Recipe) -> Bool {
        generate(for: recipe) == fingerprint
    }
}
