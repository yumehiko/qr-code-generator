import SwiftUI
import Combine

@MainActor
class QRCodeViewModel: ObservableObject {
    @Published var inputText: String = "" {
        didSet {
            scheduleQRCodeGeneration()
        }
    }
    
    @Published var qrCodeImage: NSImage?
    @Published var errorCorrectionLevel: ErrorCorrectionLevel = .medium {
        didSet {
            generateQRCode()
        }
    }
    
    @Published var isExporting = false
    @Published var exportMessage: String?
    @Published var error: QRCodeError?
    @Published private(set) var decodedContents: [String] = []
    @Published private(set) var isReading = false
    @Published private(set) var readErrorMessage: String?
    @Published private(set) var readCopyMessage: String?
    
    private let qrGenerator = QRCodeGenerator()
    private let fileExporter = FileExportService()
    private var generateWorkItem: DispatchWorkItem?
    private var readTask: Task<Void, Never>?
    private var activeReadRequestID = 0
    
    var canExport: Bool {
        qrCodeImage != nil && !inputText.isEmpty
    }
    
    private func scheduleQRCodeGeneration() {
        generateWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.generateQRCode()
            }
        }
        
        generateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    func generateQRCode() {
        error = nil
        
        guard !inputText.isEmpty else {
            qrCodeImage = nil
            return
        }
        
        let validationResult = QRCodeValidator.validate(text: inputText, correctionLevel: errorCorrectionLevel)
        if case .failure(let validationError) = validationResult {
            error = validationError
            qrCodeImage = nil
            return
        }
        
        guard let image = qrGenerator.generate(from: inputText, correctionLevel: errorCorrectionLevel) else {
            error = .generationFailed
            qrCodeImage = nil
            return
        }
        
        qrCodeImage = image
    }
    
    func exportToSVG(withDialog: Bool = false) {
        guard canExport else { return }
        
        isExporting = true
        exportMessage = nil
        error = nil
        
        Task {
            defer { isExporting = false }
            
            guard let svgContent = qrGenerator.convertToSVG(from: inputText, correctionLevel: errorCorrectionLevel) else {
                error = .exportFailed(reason: "Failed to generate SVG content")
                return
            }
            
            let result: ExportResult
            if withDialog {
                result = fileExporter.saveWithDialog(content: svgContent)
            } else {
                result = fileExporter.saveToDownloads(content: svgContent)
            }
            
            if result.success {
                exportMessage = "Saved as \(result.filename)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.exportMessage = nil
                }
            } else if let error = result.error {
                let nsError = error as NSError
                if nsError.code != 2 {
                    self.error = .exportFailed(reason: error.localizedDescription)
                }
            }
        }
    }
    
    func copyToClipboard() {
        guard qrCodeImage != nil else {
            error = .exportFailed(reason: "No QR code to copy")
            return
        }
        
        // Generate SVG content
        guard let svgContent = qrGenerator.convertToSVG(from: inputText, correctionLevel: errorCorrectionLevel) else {
            error = .exportFailed(reason: "Failed to generate SVG")
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Set SVG as text only (for Illustrator, code editors, browsers)
        let success = pasteboard.setString(svgContent, forType: .string)
        
        if success {
            exportMessage = "Copied SVG to clipboard"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.exportMessage = nil
            }
        } else {
            error = .exportFailed(reason: "Failed to copy to clipboard")
        }
    }

    @discardableResult
    func beginImageReadRequest() -> Int {
        activeReadRequestID &+= 1
        readTask?.cancel()
        decodedContents = []
        readErrorMessage = nil
        readCopyMessage = nil
        isReading = true
        return activeReadRequestID
    }

    func readQRCode(from url: URL) {
        let requestID = beginImageReadRequest()
        readQRCode(from: url, requestID: requestID)
    }

    func readQRCode(from url: URL, requestID: Int) {
        guard requestID == activeReadRequestID else { return }

        readTask = Task { [weak self] in
            let result = await Task.detached {
                QRCodeReader().read(from: url)
            }.value

            guard !Task.isCancelled, self?.activeReadRequestID == requestID else { return }

            self?.isReading = false
            switch result {
            case .success(let contents):
                self?.decodedContents = contents
            case .failure(let error):
                self?.readErrorMessage = error.localizedDescription
            }
        }
    }

    func copyDecodedContent(_ content: String) {
        NSPasteboard.general.clearContents()

        if NSPasteboard.general.setString(content, forType: .string) {
            readCopyMessage = "Copied QR code content"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.readCopyMessage = nil
            }
        } else {
            readErrorMessage = "Failed to copy QR code content."
        }
    }

    func reportImageSelectionFailure(_ error: Error, requestID: Int? = nil) {
        let currentRequestID: Int
        if let requestID {
            guard requestID == activeReadRequestID else { return }
            currentRequestID = requestID
        } else {
            currentRequestID = beginImageReadRequest()
        }

        guard currentRequestID == activeReadRequestID else { return }
        isReading = false
        readErrorMessage = "Could not select image: \(error.localizedDescription)"
    }
    
    func clearMessages() {
        exportMessage = nil
        error = nil
    }
}
