import Foundation

struct QRCodeData {
    let text: String
    let correctionLevel: ErrorCorrectionLevel
    let generatedAt: Date
    var svgContent: String?
    
    init(text: String, correctionLevel: ErrorCorrectionLevel = .medium) {
        self.text = text
        self.correctionLevel = correctionLevel
        self.generatedAt = Date()
        self.svgContent = nil
    }
}

enum ErrorCorrectionLevel: String, CaseIterable, Identifiable {
    case low = "L"      // ~7% correction
    case medium = "M"   // ~15% correction (default)
    case quartile = "Q" // ~25% correction
    case high = "H"     // ~30% correction
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .low:
            return "Low (L)"
        case .medium:
            return "Medium (M)"
        case .quartile:
            return "Quartile (Q)"
        case .high:
            return "High (H)"
        }
    }
    
    var tooltip: String {
        switch self {
        case .low:
            return "~7% error correction"
        case .medium:
            return "~15% error correction (recommended)"
        case .quartile:
            return "~25% error correction"
        case .high:
            return "~30% error correction"
        }
    }
    
    var ciLevel: String {
        switch self {
        case .low:
            return "L"
        case .medium:
            return "M"
        case .quartile:
            return "Q"
        case .high:
            return "H"
        }
    }
}

struct ExportResult {
    let success: Bool
    let filename: String
    let path: URL?
    let error: Error?
    
    static func success(filename: String, path: URL) -> ExportResult {
        ExportResult(success: true, filename: filename, path: path, error: nil)
    }
    
    static func failure(filename: String, error: Error) -> ExportResult {
        ExportResult(success: false, filename: filename, path: nil, error: error)
    }
}