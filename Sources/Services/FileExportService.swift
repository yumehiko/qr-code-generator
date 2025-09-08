import Foundation
import AppKit

class FileExportService {
    
    func saveToDownloads(content: String, filename: String? = nil) -> ExportResult {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let fileName = filename ?? generateFilename()
        let fileURL = downloadsURL.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(filename: fileName, path: fileURL)
        } catch {
            return .failure(filename: fileName, error: error)
        }
    }
    
    func saveWithDialog(content: String, suggestedName: String? = nil) -> ExportResult {
        let panel = NSSavePanel()
        panel.title = "Save QR Code"
        panel.nameFieldStringValue = suggestedName ?? generateFilename()
        panel.allowedContentTypes = [.svg]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.allowsOtherFileTypes = false
        panel.message = "Choose where to save your QR code"
        
        let response = panel.runModal()
        
        if response == .OK {
            guard let url = panel.url else {
                return .failure(
                    filename: panel.nameFieldStringValue,
                    error: NSError(domain: "FileExportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No URL selected"])
                )
            }
            
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                return .success(filename: url.lastPathComponent, path: url)
            } catch {
                return .failure(filename: url.lastPathComponent, error: error)
            }
        } else {
            return .failure(
                filename: panel.nameFieldStringValue,
                error: NSError(domain: "FileExportService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Save cancelled"])
            )
        }
    }
    
    private func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "qrcode_\(timestamp).svg"
    }
}