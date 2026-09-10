import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Vision

struct Record: Codable {
    let category: String
    let input: String
    let correctionLevel: String
    let moduleCount: Int
    let matrix: [String]
    let candidateMatrices: [[String]]?
    let visionSymbolVersion: Int?
    let visionMaskPattern: Int?
    let visionErrorCorrectionLevel: String?
    let visionErrorCorrectedPayloadHex: String?
}

func matrix(of image: CIImage, context: CIContext) throws -> [String] {
    let extent = image.extent.integral
    guard extent.width == extent.height, extent.width > 0,
          let cgImage = context.createCGImage(image, from: extent) else {
        throw NSError(domain: "Probe", code: 1)
    }
    let width = cgImage.width
    let colorSpace = CGColorSpaceCreateDeviceGray()
    var pixels = [UInt8](repeating: 0, count: width * width)
    guard let bitmap = CGContext(
        data: &pixels, width: width, height: width,
        bitsPerComponent: 8, bytesPerRow: width,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue
    ) else { throw NSError(domain: "Probe", code: 2) }
    bitmap.interpolationQuality = .none
    bitmap.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: width))
    return (0..<width).map { y in
        String((0..<width).map { x in pixels[y * width + x] < 128 ? "1" : "0" })
    }
}

func descriptor(of image: CIImage, context: CIContext) throws -> CIQRCodeDescriptor? {
    guard let cgImage = context.createCGImage(image, from: image.extent) else {
        throw NSError(domain: "Probe", code: 3)
    }
    let request = VNDetectBarcodesRequest()
    request.symbologies = [.qr]
    let handler = VNImageRequestHandler(cgImage: cgImage)
    try handler.perform([request])
    return request.results?.first?.barcodeDescriptor as? CIQRCodeDescriptor
}

func candidateMatrix(
    descriptor: CIQRCodeDescriptor, mask: Int, context: CIContext
) throws -> [String] {
    let candidate = CIQRCodeDescriptor(
        payload: descriptor.errorCorrectedPayload,
        symbolVersion: descriptor.symbolVersion,
        maskPattern: UInt8(mask),
        errorCorrectionLevel: descriptor.errorCorrectionLevel
    )
    guard let filter = CIFilter(name: "CIBarcodeGenerator") else {
        throw NSError(domain: "Probe", code: 4)
    }
    filter.setValue(candidate, forKey: "inputBarcodeDescriptor")
    guard let output = filter.outputImage else { throw NSError(domain: "Probe", code: 5) }
    return try matrix(of: output, context: context)
}

let basicSamples = [
    "https://example.com", "8675309", "HELLO WORLD", "hello world", "こんにちは世界",
    "https://example.com/item/20260910?id=42",
    "https://example.com/1234567890123456789012345678901234567890"
]
let levels = [("L", "L"), ("M", "M"), ("Q", "Q"), ("H", "H")]
let context = CIContext(options: [.useSoftwareRenderer: false])
var records: [Record] = []

for input in basicSamples {
    for (levelName, levelValue) in levels {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(input.utf8)
        filter.correctionLevel = levelValue
        guard let output = filter.outputImage else { fatalError("CIQRCodeGenerator produced no image") }
        let rows = try matrix(of: output, context: context)
        let qr = try descriptor(of: output, context: context)
        let candidates = try qr.map { descriptor in
            try (0...7).map { try candidateMatrix(descriptor: descriptor, mask: $0, context: context) }
        }
        records.append(Record(
            category: "basic",
            input: input,
            correctionLevel: levelName,
            moduleCount: rows.count,
            matrix: rows,
            candidateMatrices: candidates,
            visionSymbolVersion: qr.map { Int($0.symbolVersion) },
            visionMaskPattern: qr.map { Int($0.maskPattern) },
            visionErrorCorrectionLevel: qr.map { String(describing: $0.errorCorrectionLevel) },
            visionErrorCorrectedPayloadHex: qr.map { $0.errorCorrectedPayload.map { String(format: "%02X", $0) }.joined() }
        ))
    }
}

var optimizationInputs: [String] = []
for count in 1...24 {
    for (prefix, suffix) in [("https://example.com/", ""), ("a", "b"), ("ABC", "DEF"), ("https://example.com/", "?q=a")] {
        optimizationInputs.append(prefix + String(repeating: "1", count: count) + suffix)
    }
    optimizationInputs.append("a" + String(repeating: "A", count: count) + "b")
}
for input in optimizationInputs {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(input.utf8)
    filter.correctionLevel = "M"
    guard let output = filter.outputImage else { fatalError("CIQRCodeGenerator produced no image") }
    let rows = try matrix(of: output, context: context)
    let qr = try descriptor(of: output, context: context)
    records.append(Record(
        category: "optimization",
        input: input,
        correctionLevel: "M",
        moduleCount: rows.count,
        matrix: rows,
        candidateMatrices: nil,
        visionSymbolVersion: qr.map { Int($0.symbolVersion) },
        visionMaskPattern: qr.map { Int($0.maskPattern) },
        visionErrorCorrectionLevel: qr.map { String(describing: $0.errorCorrectionLevel) },
        visionErrorCorrectedPayloadHex: qr.map { $0.errorCorrectedPayload.map { String(format: "%02X", $0) }.joined() }
    ))
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
FileHandle.standardOutput.write(try encoder.encode(records))
FileHandle.standardOutput.write(Data("\n".utf8))
