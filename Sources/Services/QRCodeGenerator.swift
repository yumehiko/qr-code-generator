import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit

class QRCodeGenerator {
    private let context = CIContext()
    static let modulePixelSize = 10
    static let quietZoneModules = 4
    static let quietZonePixelSize = modulePixelSize * quietZoneModules
    
    func generate(from text: String, correctionLevel: ErrorCorrectionLevel) -> NSImage? {
        guard !text.isEmpty else { return nil }

        guard let qrImage = makePaddedQRCodeImage(from: text, correctionLevel: correctionLevel),
              let cgImage = context.createCGImage(qrImage, from: qrImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: qrImage.extent.size)
    }
    
    func convertToSVG(from text: String, correctionLevel: ErrorCorrectionLevel) -> String? {
        guard !text.isEmpty else { return nil }
        
        guard let qrImage = makePaddedQRCodeImage(from: text, correctionLevel: correctionLevel),
              let cgImage = context.createCGImage(qrImage, from: qrImage.extent) else {
            return nil
        }

        return generateSVGString(from: cgImage, size: qrImage.extent.size)
    }

    private func makePaddedQRCodeImage(from text: String, correctionLevel: ErrorCorrectionLevel) -> CIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = correctionLevel.ciLevel

        guard let outputImage = filter.outputImage else { return nil }

        let moduleSize = CGFloat(Self.modulePixelSize)
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: moduleSize, y: moduleSize))
        let quietZone = CGFloat(Self.quietZonePixelSize)
        let translatedImage = scaledImage.transformed(by: CGAffineTransform(
            translationX: quietZone - scaledImage.extent.minX,
            y: quietZone - scaledImage.extent.minY
        ))
        let paddedExtent = CGRect(
            x: 0,
            y: 0,
            width: scaledImage.extent.width + quietZone * 2,
            height: scaledImage.extent.height + quietZone * 2
        )
        let opaqueWhiteBackground = CIImage(color: .white).cropped(to: paddedExtent)

        return translatedImage.composited(over: opaqueWhiteBackground)
    }
    
    private func generateSVGString(from cgImage: CGImage, size: CGSize) -> String {
        let width = Int(size.width)
        let height = Int(size.height)
        
        var svgString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="\(width)" height="\(height)" viewBox="0 0 \(width) \(height)">
        <rect width="100%" height="100%" fill="white"/>
        
        """
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data else {
            return svgString + "</svg>"
        }
        
        let pixelData = CFDataGetBytePtr(data)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        
        let moduleSize = Self.modulePixelSize
        let qrWidth = width / moduleSize
        let qrHeight = height / moduleSize
        
        for y in 0..<qrHeight {
            for x in 0..<qrWidth {
                let pixelX = x * moduleSize + moduleSize / 2
                let pixelY = y * moduleSize + moduleSize / 2
                
                if pixelX < width && pixelY < height {
                    let offset = pixelY * bytesPerRow + pixelX * bytesPerPixel
                    
                    if let pixelData = pixelData {
                        let r = pixelData[offset]
                        let g = pixelData[offset + 1]
                        let b = pixelData[offset + 2]
                        
                        let brightness = (Int(r) + Int(g) + Int(b)) / 3
                        
                        if brightness < 128 {
                            svgString += """
                            <rect x="\(x * moduleSize)" y="\(y * moduleSize)" width="\(moduleSize)" height="\(moduleSize)" fill="black"/>
                            
                            """
                        }
                    }
                }
            }
        }
        
        svgString += "</svg>"
        return svgString
    }
}
