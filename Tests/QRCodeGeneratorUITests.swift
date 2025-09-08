import XCTest
import Combine
import AppKit
@testable import QRCodeGenerator

final class QRCodeGeneratorUITests: XCTestCase {
    var app: NSApplication!
    var window: NSWindow!
    var viewModel: QRCodeViewModel!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = NSApplication.shared
        viewModel = QRCodeViewModel()
    }
    
    override func tearDownWithError() throws {
        window = nil
        viewModel = nil
    }
    
    // MARK: - Text Input Tests
    
    func testTextInputTriggersAutomaticGeneration() throws {
        let expectation = XCTestExpectation(description: "QR code generated")
        
        viewModel.$qrImage
            .dropFirst()
            .sink { image in
                if image != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.inputText = "Test QR Code"
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(viewModel.qrImage)
        XCTAssertEqual(viewModel.inputText, "Test QR Code")
    }
    
    func testEmptyTextDoesNotGenerateQRCode() throws {
        viewModel.inputText = ""
        XCTAssertNil(viewModel.qrImage)
    }
    
    func testLongTextInput() throws {
        let longText = String(repeating: "A", count: 2000)
        viewModel.inputText = longText
        
        let expectation = XCTestExpectation(description: "QR code generated for long text")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(viewModel.qrImage)
    }
    
    func testSpecialCharactersInInput() throws {
        let specialText = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        viewModel.inputText = specialText
        
        let expectation = XCTestExpectation(description: "QR code generated for special characters")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(viewModel.qrImage)
    }
    
    // MARK: - Error Correction Level Tests
    
    func testErrorCorrectionLevelChanges() throws {
        viewModel.inputText = "Test"
        
        // Test Low correction level
        viewModel.correctionLevel = .L
        let lowImage = captureQRImage()
        
        // Test Medium correction level
        viewModel.correctionLevel = .M
        let mediumImage = captureQRImage()
        
        // Test Quartile correction level
        viewModel.correctionLevel = .Q
        let quartileImage = captureQRImage()
        
        // Test High correction level
        viewModel.correctionLevel = .H
        let highImage = captureQRImage()
        
        // Verify all images were generated
        XCTAssertNotNil(lowImage)
        XCTAssertNotNil(mediumImage)
        XCTAssertNotNil(quartileImage)
        XCTAssertNotNil(highImage)
        
        // Verify that different correction levels produce different QR codes
        XCTAssertNotEqual(lowImage?.tiffRepresentation, highImage?.tiffRepresentation)
    }
    
    func testDefaultErrorCorrectionLevel() throws {
        XCTAssertEqual(viewModel.correctionLevel, .M)
    }
    
    // MARK: - Save Operation Tests
    
    func testSaveOperationWithValidQRCode() throws {
        viewModel.inputText = "Save Test"
        
        // Wait for QR code generation
        let expectation = XCTestExpectation(description: "QR code generated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNotNil(viewModel.qrImage)
        
        // Test save panel would appear
        let saveExpectation = XCTestExpectation(description: "Save operation initiated")
        
        // Simulate save action
        viewModel.saveQRCode()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            saveExpectation.fulfill()
        }
        
        wait(for: [saveExpectation], timeout: 1.0)
    }
    
    func testSaveOperationWithoutQRCode() throws {
        viewModel.inputText = ""
        XCTAssertNil(viewModel.qrImage)
        
        // Attempt to save should not crash
        viewModel.saveQRCode()
        
        // Verify no image was saved (since there's no QR code)
        XCTAssertNil(viewModel.qrImage)
    }
    
    func testCopyOperationWithValidQRCode() throws {
        viewModel.inputText = "Copy Test"
        
        // Wait for QR code generation
        let expectation = XCTestExpectation(description: "QR code generated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNotNil(viewModel.qrImage)
        
        // Test copy to pasteboard
        viewModel.copyToClipboard()
        
        // Verify pasteboard contains image
        let pasteboard = NSPasteboard.general
        let pasteboardTypes = pasteboard.types ?? []
        XCTAssertTrue(pasteboardTypes.contains(.tiff) || pasteboardTypes.contains(.png))
    }
    
    // MARK: - UI State Tests
    
    func testInitialUIState() throws {
        XCTAssertEqual(viewModel.inputText, "")
        XCTAssertNil(viewModel.qrImage)
        XCTAssertEqual(viewModel.correctionLevel, .M)
        XCTAssertFalse(viewModel.isGenerating)
    }
    
    func testGeneratingStateWhileProcessing() throws {
        let longText = String(repeating: "A", count: 5000)
        
        viewModel.inputText = longText
        
        // Check that isGenerating becomes true during processing
        let expectation = XCTestExpectation(description: "Generation state changes")
        
        var generatingStateObserved = false
        viewModel.$isGenerating
            .sink { isGenerating in
                if isGenerating {
                    generatingStateObserved = true
                }
                if !isGenerating && generatingStateObserved {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(generatingStateObserved)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndQRCodeGenerationAndSave() throws {
        // Input text
        viewModel.inputText = "https://example.com"
        
        // Wait for generation
        let genExpectation = XCTestExpectation(description: "QR code generated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            genExpectation.fulfill()
        }
        wait(for: [genExpectation], timeout: 1.0)
        
        // Verify QR code exists
        XCTAssertNotNil(viewModel.qrImage)
        
        // Change error correction level
        viewModel.correctionLevel = .H
        
        // Wait for regeneration
        let regenExpectation = XCTestExpectation(description: "QR code regenerated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            regenExpectation.fulfill()
        }
        wait(for: [regenExpectation], timeout: 1.0)
        
        // Verify QR code still exists
        XCTAssertNotNil(viewModel.qrImage)
        
        // Copy to clipboard
        viewModel.copyToClipboard()
        
        // Verify clipboard contains image
        let pasteboard = NSPasteboard.general
        XCTAssertNotNil(pasteboard.data(forType: .tiff))
    }
    
    func testRapidTextChanges() throws {
        let texts = ["A", "AB", "ABC", "ABCD", "ABCDE"]
        
        for text in texts {
            viewModel.inputText = text
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Wait for final generation
        let expectation = XCTestExpectation(description: "Final QR code generated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Verify final state
        XCTAssertEqual(viewModel.inputText, "ABCDE")
        XCTAssertNotNil(viewModel.qrImage)
    }
    
    // MARK: - Helper Methods
    
    private var cancellables = Set<AnyCancellable>()
    
    private func captureQRImage() -> NSImage? {
        let expectation = XCTestExpectation(description: "Capture QR image")
        var capturedImage: NSImage?
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            capturedImage = self.viewModel.qrImage
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        return capturedImage
    }
}

// MARK: - Performance Tests

extension QRCodeGeneratorUITests {
    func testPerformanceOfQRCodeGeneration() throws {
        measure {
            viewModel.inputText = "Performance Test \(UUID().uuidString)"
            _ = captureQRImage()
        }
    }
    
    func testPerformanceOfLargeTextGeneration() throws {
        let largeText = String(repeating: "Lorem ipsum dolor sit amet, ", count: 50)
        
        measure {
            viewModel.inputText = largeText
            _ = captureQRImage()
        }
    }
}