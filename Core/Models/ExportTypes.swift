import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case jpeg, heic
    var id: String { rawValue }
    var label: String {
        switch self {
        case .jpeg: return "JPEG"
        case .heic: return "HEIC"
        }
    }
}

enum ExportQuality: String, CaseIterable, Identifiable {
    case small, medium, full
    var id: String { rawValue }
    var label: String {
        switch self {
        case .small:  return "Small"
        case .medium: return "Medium"
        case .full:   return "Full Resolution"
        }
    }
    var description: String {
        switch self {
        case .small:  return "Max 1024 px — smallest file size"
        case .medium: return "Max 2048 px — balanced"
        case .full:   return "Original resolution — largest file"
        }
    }
    var maxDimension: CGFloat? {
        switch self {
        case .small:  return 1024
        case .medium: return 2048
        case .full:   return nil
        }
    }
}
