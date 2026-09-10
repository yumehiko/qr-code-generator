import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = QRCodeViewModel()
    @State private var isImportingImage = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    QRDisplayView(qrImage: viewModel.qrCodeImage)
                        .frame(width: 240, height: 240)
                    ExportButton(viewModel: viewModel)
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 12) {
                    Label("⌘C Copy", systemImage: "keyboard")
                    Label("⌘E Export", systemImage: "keyboard")
                    Label("⌘⇧E Save As", systemImage: "keyboard")
                    Label("⌘K Clear", systemImage: "keyboard")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

                Divider()

                TextInputView(text: $viewModel.inputText, error: viewModel.error)
                    .frame(maxWidth: .infinity)

                ErrorCorrectionPicker(selection: $viewModel.errorCorrectionLevel)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                ImageDropArea(viewModel: viewModel) {
                    isImportingImage = true
                }

                QRCodeReadResultsView(viewModel: viewModel)
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle("QR Code Generator")
        .errorAlert($viewModel.error)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.inputText = ""
                }) {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(viewModel.inputText.isEmpty)
                .help("Clear text input")
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    isImportingImage = true
                } label: {
                    Label("Read Image", systemImage: "viewfinder")
                }
                .help("Select an image and read its QR codes")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ClearText"))) { _ in
            viewModel.inputText = ""
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SaveToDownloads"))) { _ in
            viewModel.exportToSVG(withDialog: false)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SaveAs"))) { _ in
            viewModel.exportToSVG(withDialog: true)
        }
        .fileImporter(
            isPresented: $isImportingImage,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.readQRCode(from: url)
                }
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError {
                    viewModel.reportImageSelectionFailure(error)
                }
            }
        }
    }
}
