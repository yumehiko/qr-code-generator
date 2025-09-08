import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = QRCodeViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Upper section: QR Code Preview
            VStack(spacing: 8) {
                QRDisplayView(qrImage: viewModel.qrCodeImage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Keyboard shortcuts help text
                HStack(spacing: 20) {
                    Label("⌘C: Copy", systemImage: "keyboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label("⌘E: Export", systemImage: "keyboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label("⌘⇧E: Save As", systemImage: "keyboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label("⌘K: Clear Text", systemImage: "keyboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }
            .padding()
            
            Divider()
            
            // Lower section: Input and Controls
            HStack(spacing: 16) {
                TextInputView(
                    text: $viewModel.inputText,
                    error: viewModel.error
                )
                .frame(maxWidth: .infinity)
                
                ControlsView(
                    errorCorrectionLevel: $viewModel.errorCorrectionLevel,
                    viewModel: viewModel
                )
            }
            .padding()
            .frame(height: 120)
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
    }
}