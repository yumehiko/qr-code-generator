import XCTest
import Combine
@testable import QRCodeGeneratorLib

final class QRCodeViewModelTests: XCTestCase {
    
    var viewModel: QRCodeViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = QRCodeViewModel()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.inputText, "", "Initial input text should be empty")
        XCTAssertNil(viewModel.qrCodeImage, "Initial QR code image should be nil")
        XCTAssertEqual(viewModel.selectedCorrectionLevel, .M, "Default correction level should be Medium")
        XCTAssertFalse(viewModel.isExporting, "Should not be exporting initially")
        XCTAssertNil(viewModel.exportResult, "Export result should be nil initially")
    }
    
    // MARK: - Text Input Tests
    
    func testTextInputUpdatesGenerateQRCode() {
        let expectation = XCTestExpectation(description: "QR code generated after text input")
        
        viewModel.$qrCodeImage
            .dropFirst() // Skip initial nil value
            .sink { image in
                XCTAssertNotNil(image, "QR code image should be generated")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.inputText = "Test input"
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testEmptyTextClearsQRCode() {
        // First generate a QR code
        viewModel.inputText = "Some text"
        
        // Wait for generation
        let generateExpectation = XCTestExpectation(description: "QR code generated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNotNil(self.viewModel.qrCodeImage, "QR code should be generated")
            generateExpectation.fulfill()
        }
        wait(for: [generateExpectation], timeout: 1.0)
        
        // Now clear the text
        let clearExpectation = XCTestExpectation(description: "QR code cleared")
        
        viewModel.$qrCodeImage
            .dropFirst()
            .sink { image in
                if image == nil {
                    clearExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.inputText = ""
        
        wait(for: [clearExpectation], timeout: 1.0)
    }
    
    func testTextInputDebouncing() {
        var generationCount = 0
        let expectation = XCTestExpectation(description: "Debounced generation")
        
        viewModel.$qrCodeImage
            .dropFirst()
            .sink { _ in
                generationCount += 1
                if generationCount == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Rapidly change text multiple times
        viewModel.inputText = "T"
        viewModel.inputText = "Te"
        viewModel.inputText = "Tes"
        viewModel.inputText = "Test"
        
        wait(for: [expectation], timeout: 1.5)
        
        // Should only generate once due to debouncing
        XCTAssertEqual(generationCount, 1, "Should only generate QR code once due to debouncing")
    }
    
    // MARK: - Error Correction Level Tests
    
    func testChangingCorrectionLevelRegeneratesQRCode() {
        viewModel.inputText = "Test text"
        
        // Wait for initial generation
        let initialExpectation = XCTestExpectation(description: "Initial generation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            initialExpectation.fulfill()
        }
        wait(for: [initialExpectation], timeout: 1.0)
        
        let firstImage = viewModel.qrCodeImage
        XCTAssertNotNil(firstImage, "Should have initial QR code")
        
        // Change correction level
        let regenerateExpectation = XCTestExpectation(description: "Regeneration after level change")
        
        viewModel.$qrCodeImage
            .dropFirst()
            .sink { _ in
                regenerateExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.selectedCorrectionLevel = .H
        
        wait(for: [regenerateExpectation], timeout: 1.0)
        
        XCTAssertNotNil(viewModel.qrCodeImage, "Should have regenerated QR code")
    }
    
    func testAllCorrectionLevels() {
        viewModel.inputText = "Test all levels"
        
        let levels: [ErrorCorrectionLevel] = [.L, .M, .Q, .H]
        
        for level in levels {
            let expectation = XCTestExpectation(description: "Generation for level \(level)")
            
            viewModel.$qrCodeImage
                .dropFirst()
                .first()
                .sink { image in
                    XCTAssertNotNil(image, "Should generate QR code for level \(level)")
                    expectation.fulfill()
                }
                .store(in: &cancellables)
            
            viewModel.selectedCorrectionLevel = level
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Export Tests
    
    func testExportToSVG() {
        // First generate a QR code
        viewModel.inputText = "Export test"
        
        let generateExpectation = XCTestExpectation(description: "QR code generated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNotNil(self.viewModel.qrCodeImage, "QR code should be generated before export")
            generateExpectation.fulfill()
        }
        wait(for: [generateExpectation], timeout: 1.0)
        
        // Test export
        let exportExpectation = XCTestExpectation(description: "Export completed")
        
        viewModel.$isExporting
            .sink { isExporting in
                if !isExporting && self.viewModel.exportResult != nil {
                    exportExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.exportToSVG()
        
        wait(for: [exportExpectation], timeout: 5.0)
        
        XCTAssertFalse(viewModel.isExporting, "Should not be exporting after completion")
    }
    
    func testExportWithoutQRCode() {
        // Ensure no QR code is generated
        XCTAssertNil(viewModel.qrCodeImage, "Should not have QR code")
        
        viewModel.exportToSVG()
        
        // Should not start exporting
        XCTAssertFalse(viewModel.isExporting, "Should not export without QR code")
    }
    
    func testExportWithSaveDialog() {
        viewModel.inputText = "Dialog export test"
        
        // Wait for generation
        let generateExpectation = XCTestExpectation(description: "QR code generated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            generateExpectation.fulfill()
        }
        wait(for: [generateExpectation], timeout: 1.0)
        
        // Test export with dialog (withDialog: true)
        viewModel.exportToSVG(withDialog: true)
        
        // Note: Can't fully test NSSavePanel in unit tests
        // Just verify the method doesn't crash
        XCTAssertTrue(true, "Export with dialog method should execute without crashing")
    }
    
    // MARK: - State Management Tests
    
    func testIsExportingState() {
        viewModel.inputText = "State test"
        
        // Wait for generation
        let generateExpectation = XCTestExpectation(description: "QR code generated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            generateExpectation.fulfill()
        }
        wait(for: [generateExpectation], timeout: 1.0)
        
        var stateChanges: [Bool] = []
        let stateExpectation = XCTestExpectation(description: "Export state changes")
        
        viewModel.$isExporting
            .sink { isExporting in
                stateChanges.append(isExporting)
                if stateChanges.count >= 2 {
                    stateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.exportToSVG()
        
        wait(for: [stateExpectation], timeout: 5.0)
        
        // Should transition from false -> true -> false
        XCTAssertTrue(stateChanges.contains(true), "Should set isExporting to true during export")
        XCTAssertTrue(stateChanges.last == false, "Should set isExporting to false after export")
    }
    
    // MARK: - Performance Tests
    
    func testQRGenerationPerformance() {
        measure {
            viewModel.inputText = "Performance test text"
            
            let expectation = XCTestExpectation(description: "QR generation")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryLeaks() {
        weak var weakViewModel: QRCodeViewModel?
        
        autoreleasepool {
            let vm = QRCodeViewModel()
            weakViewModel = vm
            
            vm.inputText = "Memory test"
            
            // Simulate some operations
            let expectation = XCTestExpectation(description: "Operations complete")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
        
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
    }
    
    // MARK: - Edge Cases
    
    func testVeryLongTextInput() {
        let longText = String(repeating: "A", count: 2000)
        viewModel.inputText = longText
        
        let expectation = XCTestExpectation(description: "Long text processed")
        
        viewModel.$qrCodeImage
            .dropFirst()
            .sink { image in
                XCTAssertNotNil(image, "Should generate QR code for long text")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSpecialCharactersInText() {
        let specialText = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        viewModel.inputText = specialText
        
        let expectation = XCTestExpectation(description: "Special characters processed")
        
        viewModel.$qrCodeImage
            .dropFirst()
            .sink { image in
                XCTAssertNotNil(image, "Should generate QR code for special characters")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUnicodeTextInput() {
        let unicodeText = "Hello 世界 🌍 مرحبا"
        viewModel.inputText = unicodeText
        
        let expectation = XCTestExpectation(description: "Unicode processed")
        
        viewModel.$qrCodeImage
            .dropFirst()
            .sink { image in
                XCTAssertNotNil(image, "Should generate QR code for Unicode text")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}