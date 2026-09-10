import SwiftUI

struct QRCodeReadResultsView: View {
    @ObservedObject var viewModel: QRCodeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.decodedContents.isEmpty {
                Text("Detected \(viewModel.decodedContents.count) QR code\(viewModel.decodedContents.count == 1 ? "" : "s").")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(viewModel.decodedContents.enumerated()), id: \.offset) { index, content in
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("QR Code \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(content)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 8)
                                Button {
                                    viewModel.copyDecodedContent(content)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .help("Copy this QR code content")
                            }
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }

            if let message = viewModel.readCopyMessage {
                Label(message, systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }
}
