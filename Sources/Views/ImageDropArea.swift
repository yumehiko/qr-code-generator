import SwiftUI
import UniformTypeIdentifiers

struct ImageDropArea: View {
    @ObservedObject var viewModel: QRCodeViewModel
    let selectImage: () -> Void
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Read QR Code", systemImage: "viewfinder")
                    .font(.headline)
                Spacer()
                Button("Select Image...", action: selectImage)
                    .disabled(viewModel.isReading)
            }

            dropContent
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 74, alignment: .center)
                .background(isTargeted ? Color.accentColor.opacity(0.14) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isTargeted ? Color.accentColor : Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [5]))
                )
                .cornerRadius(8)
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted, perform: acceptDrop)
                .accessibilityLabel("QR code image drop area")
                .accessibilityHint("Drop an image file here to read its QR codes")

        }
    }

    @ViewBuilder
    private var dropContent: some View {
        if viewModel.isReading {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Reading QR code from image...").foregroundColor(.secondary)
            }
        } else if let message = viewModel.readErrorMessage {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption)
        } else {
            Image(systemName: "arrow.down.doc")
                .font(.title2)
            .foregroundColor(.secondary)
        }
    }

    private func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        let requestID = viewModel.beginImageReadRequest()

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            DispatchQueue.main.async {
                if let error {
                    viewModel.reportImageSelectionFailure(error, requestID: requestID)
                    return
                }

                let url: URL?
                if let item = item as? URL {
                    url = item
                } else if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else {
                    url = nil
                }

                guard let url, url.isFileURL else {
                    viewModel.reportImageSelectionFailure(ImageDropError.invalidFile, requestID: requestID)
                    return
                }
                viewModel.readQRCode(from: url, requestID: requestID)
            }
        }
        return true
    }
}

private enum ImageDropError: LocalizedError {
    case invalidFile

    var errorDescription: String? { "The dropped item was not an image file." }
}
