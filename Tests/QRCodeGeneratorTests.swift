import XCTest
import AppKit
import Vision
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
        // Core Image's symbol has one white module before the finder pattern;
        // the exported SVG adds four more modules around that symbol.
        XCTAssertTrue(svg?.contains("<rect x=\"50\" y=\"50\"") == true)
    }

    func testGeneratedImagesHaveOpaqueFourModuleQuietZoneForDifferentSymbolSizes() throws {
        let generator = QRCodeGenerator()
        let inputs = ["small", String(repeating: "A", count: 300)]

        XCTAssertEqual(
            QRCodeGenerator.quietZonePixelSize,
            QRCodeGenerator.modulePixelSize * QRCodeGenerator.quietZoneModules
        )

        for input in inputs {
            let image = try XCTUnwrap(generator.generate(from: input, correctionLevel: .medium))
            let cgImage = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
            let pixels = try rgbaPixels(in: cgImage)
            let quietZone = QRCodeGenerator.quietZonePixelSize

            XCTAssertGreaterThan(cgImage.width, quietZone * 2)
            XCTAssertGreaterThan(cgImage.height, quietZone * 2)
            XCTAssertOpaqueWhiteBorder(
                pixels: pixels,
                width: cgImage.width,
                height: cgImage.height,
                borderWidth: quietZone
            )
        }
    }

    func testGeneratedImageCanBeReadBackAfterQuietZoneIsAdded() throws {
        let text = "https://example.com/quiet-zone"
        let image = try XCTUnwrap(QRCodeGenerator().generate(from: text, correctionLevel: .medium))
        let cgImage = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]

        try VNImageRequestHandler(cgImage: cgImage).perform([request])

        let decodedValues = request.results?.compactMap(\.payloadStringValue) ?? []
        XCTAssertTrue(decodedValues.contains(text))
    }

    func testReaderPreservesJapaneseURL() throws {
        let text = "https://example.com/検索?q=日本語"
        let image = try XCTUnwrap(QRCodeGenerator().generate(from: text, correctionLevel: .medium))
        let cgImage = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))

        let result = QRCodeReader().read(from: cgImage)

        XCTAssertEqual(try result.get(), [text])
    }

    func testReaderPreservesLongPayloadIncludingItsEnding() throws {
        let text = String(repeating: "long QR content ", count: 40) + "末尾"
        let image = try XCTUnwrap(QRCodeGenerator().generate(from: text, correctionLevel: .medium))
        let cgImage = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))

        let result = QRCodeReader().read(from: cgImage)

        XCTAssertEqual(try result.get(), [text])
    }

    func testReaderReportsNoQRCodeForPlainImage() throws {
        let image = try XCTUnwrap(makeSolidImage(width: 100, height: 100))

        XCTAssertEqual(QRCodeReader().read(from: image), .failure(.noQRCodeFound))
    }

    func testReaderReturnsAllDetectedQRCodes() throws {
        let first = try XCTUnwrap(QRCodeGenerator().generate(from: "first QR", correctionLevel: .medium))
        let second = try XCTUnwrap(QRCodeGenerator().generate(from: "second QR", correctionLevel: .medium))
        let firstCGImage = try XCTUnwrap(first.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let secondCGImage = try XCTUnwrap(second.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let combined = try XCTUnwrap(combine(firstCGImage, secondCGImage))

        let contents = try QRCodeReader().read(from: combined).get()

        XCTAssertEqual(Set(contents), Set(["first QR", "second QR"]))
    }

    func testViewModelClearsReadResultAfterUnreadableImage() async throws {
        let text = "read then clear"
        let image = try XCTUnwrap(QRCodeGenerator().generate(from: text, correctionLevel: .medium))
        let cgImage = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let pngData = try XCTUnwrap(NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]))
        let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        try pngData.write(to: imageURL)
        defer { try? FileManager.default.removeItem(at: imageURL) }

        let viewModel = await MainActor.run { QRCodeViewModel() }
        await MainActor.run { viewModel.readQRCode(from: imageURL) }
        await waitForReadingToFinish(viewModel)
        let decodedContents = await MainActor.run { viewModel.decodedContents }
        XCTAssertEqual(decodedContents, [text])

        await MainActor.run {
            viewModel.readQRCode(from: URL(fileURLWithPath: "/tmp/not-an-image-\(UUID().uuidString)"))
        }
        let contentsAfterNewRequest = await MainActor.run { viewModel.decodedContents }
        XCTAssertTrue(contentsAfterNewRequest.isEmpty)
        await waitForReadingToFinish(viewModel)
        let contentsAfterFailure = await MainActor.run { viewModel.decodedContents }
        let errorMessage = await MainActor.run { viewModel.readErrorMessage }
        XCTAssertTrue(contentsAfterFailure.isEmpty)
        XCTAssertNotNil(errorMessage)
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

    private func rgbaPixels(in image: CGImage) throws -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let context = pixels.withUnsafeMutableBytes { buffer in
            CGContext(
                data: buffer.baseAddress,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        }
        let bitmapContext = try XCTUnwrap(context)
        bitmapContext.interpolationQuality = .none
        bitmapContext.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return pixels
    }

    private func makeSolidImage(width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    private func combine(_ first: CGImage, _ second: CGImage) -> CGImage? {
        let gap = 40
        let width = first.width + second.width + gap
        let height = max(first.height, second.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .none
        context.draw(first, in: CGRect(x: 0, y: 0, width: first.width, height: first.height))
        context.draw(second, in: CGRect(x: first.width + gap, y: 0, width: second.width, height: second.height))
        return context.makeImage()
    }

    private func waitForReadingToFinish(_ viewModel: QRCodeViewModel) async {
        for _ in 0..<100 {
            if await MainActor.run(body: { !viewModel.isReading }) {
                return
            }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTFail("Timed out waiting for QR code reading")
    }

    private func XCTAssertOpaqueWhiteBorder(
        pixels: [UInt8],
        width: Int,
        height: Int,
        borderWidth: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for y in 0..<height {
            for x in 0..<width where x < borderWidth || x >= width - borderWidth || y < borderWidth || y >= height - borderWidth {
                let offset = (y * width + x) * 4
                XCTAssertEqual(pixels[offset], 255, "Red channel at (\(x), \(y))", file: file, line: line)
                XCTAssertEqual(pixels[offset + 1], 255, "Green channel at (\(x), \(y))", file: file, line: line)
                XCTAssertEqual(pixels[offset + 2], 255, "Blue channel at (\(x), \(y))", file: file, line: line)
                XCTAssertEqual(pixels[offset + 3], 255, "Alpha channel at (\(x), \(y))", file: file, line: line)
            }
        }
    }
}
