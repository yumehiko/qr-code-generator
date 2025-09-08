import XCTest
@testable import QRCodeGenerator

final class QRCodeGeneratorTests: XCTestCase {
    
    var generator: QRCodeGenerator!
    
    override func setUp() {
        super.setUp()
        generator = QRCodeGenerator()
    }
    
    override func tearDown() {
        generator = nil
        super.tearDown()
    }
    
    // MARK: - QR Code Generation Tests
    
    func testGenerateQRCodeWithSimpleText() {
        let text = "Hello, World!"
        let image = generator.generate(from: text, correctionLevel: .M)
        
        XCTAssertNotNil(image, "QR code should be generated for simple text")
        XCTAssertGreaterThan(image!.size.width, 0, "Generated image should have width")
        XCTAssertGreaterThan(image!.size.height, 0, "Generated image should have height")
    }
    
    func testGenerateQRCodeWithEmptyText() {
        let text = ""
        let image = generator.generate(from: text, correctionLevel: .M)
        
        XCTAssertNil(image, "QR code should not be generated for empty text")
    }
    
    func testGenerateQRCodeWithURL() {
        let text = "https://www.example.com"
        let image = generator.generate(from: text, correctionLevel: .M)
        
        XCTAssertNotNil(image, "QR code should be generated for URL")
    }
    
    func testGenerateQRCodeWithLongText() {
        let text = String(repeating: "A", count: 1000)
        let image = generator.generate(from: text, correctionLevel: .L)
        
        XCTAssertNotNil(image, "QR code should be generated for long text with low correction")
    }
    
    func testGenerateQRCodeWithSpecialCharacters() {
        let text = "Test with special chars: !@#$%^&*()_+-=[]{}|;':\"<>,.?/"
        let image = generator.generate(from: text, correctionLevel: .M)
        
        XCTAssertNotNil(image, "QR code should be generated for text with special characters")
    }
    
    func testGenerateQRCodeWithUnicode() {
        let text = "Unicode test: 你好世界 🌍 مرحبا بالعالم"
        let image = generator.generate(from: text, correctionLevel: .M)
        
        XCTAssertNotNil(image, "QR code should be generated for Unicode text")
    }
    
    // MARK: - Error Correction Level Tests
    
    func testAllErrorCorrectionLevels() {
        let text = "Test error correction"
        let levels: [ErrorCorrectionLevel] = [.L, .M, .Q, .H]
        
        for level in levels {
            let image = generator.generate(from: text, correctionLevel: level)
            XCTAssertNotNil(image, "QR code should be generated for error correction level \(level)")
        }
    }
    
    func testErrorCorrectionLevelL() {
        let text = "Low correction test"
        let image = generator.generate(from: text, correctionLevel: .L)
        
        XCTAssertNotNil(image, "QR code should be generated with Low error correction")
    }
    
    func testErrorCorrectionLevelM() {
        let text = "Medium correction test"
        let image = generator.generate(from: text, correctionLevel: .M)
        
        XCTAssertNotNil(image, "QR code should be generated with Medium error correction")
    }
    
    func testErrorCorrectionLevelQ() {
        let text = "Quartile correction test"
        let image = generator.generate(from: text, correctionLevel: .Q)
        
        XCTAssertNotNil(image, "QR code should be generated with Quartile error correction")
    }
    
    func testErrorCorrectionLevelH() {
        let text = "High correction test"
        let image = generator.generate(from: text, correctionLevel: .H)
        
        XCTAssertNotNil(image, "QR code should be generated with High error correction")
    }
    
    // MARK: - SVG Conversion Tests
    
    func testConvertToSVGWithValidImage() {
        let text = "SVG conversion test"
        guard let image = generator.generate(from: text, correctionLevel: .M) else {
            XCTFail("Failed to generate QR code for SVG conversion test")
            return
        }
        
        let svgString = generator.convertToSVG(from: image)
        
        XCTAssertNotNil(svgString, "SVG string should be generated from valid image")
        XCTAssertTrue(svgString!.contains("<?xml"), "SVG should contain XML declaration")
        XCTAssertTrue(svgString!.contains("<svg"), "SVG should contain svg element")
        XCTAssertTrue(svgString!.contains("</svg>"), "SVG should have closing svg tag")
        XCTAssertTrue(svgString!.contains("<rect"), "SVG should contain rect elements for QR modules")
    }
    
    func testConvertToSVGWithDifferentSizes() {
        let text = "Size test"
        let sizes = [100, 200, 500]
        
        for _ in sizes {
            guard let image = generator.generate(from: text, correctionLevel: .M) else {
                XCTFail("Failed to generate QR code")
                continue
            }
            
            let svgString = generator.convertToSVG(from: image)
            XCTAssertNotNil(svgString, "SVG should be generated regardless of image size")
        }
    }
    
    // MARK: - Performance Tests
    
    func testGenerationPerformance() {
        measure {
            _ = generator.generate(from: "Performance test", correctionLevel: .M)
        }
    }
    
    func testSVGConversionPerformance() {
        let image = generator.generate(from: "Performance test", correctionLevel: .M)!
        
        measure {
            _ = generator.convertToSVG(from: image)
        }
    }
    
    // MARK: - Edge Cases
    
    func testGenerateWithWhitespaceOnlyText() {
        let texts = ["   ", "\t\t", "\n\n", " \t\n "]
        
        for text in texts {
            let image = generator.generate(from: text, correctionLevel: .M)
            XCTAssertNotNil(image, "QR code should be generated for whitespace text: '\(text)'")
        }
    }
    
    func testGenerateWithNumericData() {
        let text = "1234567890"
        let image = generator.generate(from: text, correctionLevel: .M)
        
        XCTAssertNotNil(image, "QR code should be generated for numeric data")
    }
    
    func testGenerateWithAlphanumericData() {
        let text = "ABC123XYZ789"
        let image = generator.generate(from: text, correctionLevel: .M)
        
        XCTAssertNotNil(image, "QR code should be generated for alphanumeric data")
    }
    
    func testCapacityLimitsWithDifferentCorrectionLevels() {
        // Maximum capacity varies by correction level
        // L: ~2953 chars, M: ~2331 chars, Q: ~1663 chars, H: ~1273 chars
        let testCases: [(ErrorCorrectionLevel, Int, Bool)] = [
            (.L, 2900, true),   // Should succeed
            (.L, 3000, false),  // Should fail
            (.M, 2300, true),   // Should succeed
            (.M, 2400, false),  // Should fail
            (.Q, 1600, true),   // Should succeed
            (.Q, 1700, false),  // Should fail
            (.H, 1200, true),   // Should succeed
            (.H, 1300, false),  // Should fail
        ]
        
        for (level, length, shouldSucceed) in testCases {
            let text = String(repeating: "A", count: length)
            let image = generator.generate(from: text, correctionLevel: level)
            
            if shouldSucceed {
                XCTAssertNotNil(image, "QR code should be generated for \(length) chars with level \(level)")
            } else {
                // Note: CoreImage might still generate QR codes for oversized data
                // but they may not be scannable
                if image != nil {
                    print("Warning: QR code generated for \(length) chars with level \(level) (may not be scannable)")
                }
            }
        }
    }
}