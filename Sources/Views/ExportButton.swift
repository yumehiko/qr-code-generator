import SwiftUI

struct ExportButton: View {
    @ObservedObject var viewModel: QRCodeViewModel
    @State private var isHoveringWithOption = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(spacing: 8) {
                // Copy to Clipboard Button
                Button(action: {
                    viewModel.copyToClipboard()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Copy")
                    }
                }
                .disabled(!viewModel.canExport)
                .keyboardShortcut("c", modifiers: .command)
                .help("Copy QR code as SVG to clipboard")

                // Export SVG Button
                Button(action: {
                    let event = NSApp.currentEvent
                    let withDialog = event?.modifierFlags.contains(.option) ?? false
                    viewModel.exportToSVG(withDialog: withDialog)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isHoveringWithOption ? "square.and.arrow.down.on.square" : "square.and.arrow.down")
                        Text(isHoveringWithOption ? "Save As..." : "Export SVG")
                    }
                }
                .disabled(!viewModel.canExport || viewModel.isExporting)
                .keyboardShortcut("e", modifiers: .command)
                .help("Click to save to Downloads folder. Hold Option (⌥) to choose location.")
                .onHover { hovering in
                    if hovering {
                        let event = NSApp.currentEvent
                        isHoveringWithOption = event?.modifierFlags.contains(.option) ?? false
                    } else {
                        isHoveringWithOption = false
                    }
                }
            }

            if let exportMessage = viewModel.exportMessage {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(exportMessage)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }
        }
    }
}
