import Foundation
import ImageIO
import Vision

enum QRCodeReaderError: LocalizedError, Equatable {
    case unreadableImage
    case noQRCodeFound
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "The selected file could not be read as an image."
        case .noQRCodeFound:
            return "No QR code was found in the selected image."
        case .recognitionFailed:
            return "The QR code could not be read from the selected image."
        }
    }
}

final class QRCodeReader {
    func read(from url: URL) -> Result<[String], QRCodeReaderError> {
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return .failure(.unreadableImage)
        }

        return read(from: image)
    }

    func read(from image: CGImage) -> Result<[String], QRCodeReaderError> {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]

        do {
            try VNImageRequestHandler(cgImage: image).perform([request])
        } catch {
            return .failure(.recognitionFailed)
        }

        let contents = request.results?.compactMap(\.payloadStringValue) ?? []
        return contents.isEmpty ? .failure(.noQRCodeFound) : .success(contents)
    }
}
