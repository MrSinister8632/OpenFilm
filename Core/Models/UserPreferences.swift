import Foundation
import SwiftData

@Model
final class UserPreferences {
    var exportQualityRaw: String
    var exportFormatRaw: String

    var exportQuality: ExportQuality {
        get { ExportQuality(rawValue: exportQualityRaw) ?? .full }
        set { exportQualityRaw = newValue.rawValue }
    }

    var exportFormat: ExportFormat {
        get { ExportFormat(rawValue: exportFormatRaw) ?? .jpeg }
        set { exportFormatRaw = newValue.rawValue }
    }

    init() {
        self.exportQualityRaw = ExportQuality.full.rawValue
        self.exportFormatRaw  = ExportFormat.jpeg.rawValue
    }
}
