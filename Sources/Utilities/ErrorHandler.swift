import SwiftUI

enum QRCodeError: LocalizedError, Identifiable {
    case textTooLong(maxLength: Int)
    case generationFailed
    case exportFailed(reason: String)
    case invalidInput
    
    var id: String {
        switch self {
        case .textTooLong(let maxLength):
            return "textTooLong_\(maxLength)"
        case .generationFailed:
            return "generationFailed"
        case .exportFailed(let reason):
            return "exportFailed_\(reason)"
        case .invalidInput:
            return "invalidInput"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .textTooLong(let maxLength):
            return "Text is too long for QR code generation. Maximum length is \(maxLength) characters."
        case .generationFailed:
            return "Failed to generate QR code. Please try again."
        case .exportFailed(let reason):
            return "Failed to export QR code: \(reason)"
        case .invalidInput:
            return "Invalid input. Please enter valid text."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .textTooLong:
            return "Try shortening your text or using a higher error correction level."
        case .generationFailed:
            return "Check your input and try again."
        case .exportFailed:
            return "Ensure you have write permissions to the selected location."
        case .invalidInput:
            return "Enter valid text characters only."
        }
    }
}

struct ErrorAlert: ViewModifier {
    @Binding var error: QRCodeError?
    
    func body(content: Content) -> some View {
        content
            .alert(item: $error) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.errorDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<QRCodeError?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}

class QRCodeValidator {
    static let maxTextLength = 4296
    static let maxTextLengthByLevel: [ErrorCorrectionLevel: Int] = [
        .low: 4296,
        .medium: 3351,
        .quartile: 2331,
        .high: 1817
    ]
    
    static func validate(text: String, correctionLevel: ErrorCorrectionLevel) -> Result<Void, QRCodeError> {
        guard !text.isEmpty else {
            return .failure(.invalidInput)
        }
        
        let maxLength = maxTextLengthByLevel[correctionLevel] ?? maxTextLength
        guard text.count <= maxLength else {
            return .failure(.textTooLong(maxLength: maxLength))
        }
        
        return .success(())
    }
}