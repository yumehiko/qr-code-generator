import XCTest
@testable import QRCodeGenerator

final class QRCodeGeneratorTests: XCTestCase {
    func testGeneratorCreatesImagesForEachCorrectionLevel() {
        let generator = QRCodeGenerator()

        for level in ErrorCorrectionLevel.allCases {
            let image = generator.generate(from: "QR Code Generator", correctionLevel: level)
            XCTAssertNotNil(image, "Expected an image for \(level.rawValue)")
        }
    }

    func testGeneratorRejectsEmptyText() {
        XCTAssertNil(QRCodeGenerator().generate(from: "", correctionLevel: .medium))
    }

    func testSVGExportProducesDocument() {
        let svg = QRCodeGenerator().convertToSVG(from: "https://example.com", correctionLevel: .medium)
        XCTAssertTrue(svg?.contains("<svg") == true)
        XCTAssertTrue(svg?.contains("</svg>") == true)
    }

    func testValidatorHonorsCorrectionLevelLimit() {
        let tooLong = String(repeating: "a", count: QRCodeValidator.maxTextLengthByLevel[.high]! + 1)

        if case .failure(.textTooLong) = QRCodeValidator.validate(text: tooLong, correctionLevel: .high) {
            return
        }
        XCTFail("Expected high correction limit to be enforced")
    }

    func testViewModelGeneratesAndClearsOnMainActor() async {
        await MainActor.run {
            let viewModel = QRCodeViewModel()
            viewModel.inputText = "Test input"
            viewModel.generateQRCode()
            XCTAssertNotNil(viewModel.qrCodeImage)
            XCTAssertTrue(viewModel.canExport)

            viewModel.inputText = ""
            viewModel.generateQRCode()
            XCTAssertNil(viewModel.qrCodeImage)
            XCTAssertFalse(viewModel.canExport)
        }
    }
}
