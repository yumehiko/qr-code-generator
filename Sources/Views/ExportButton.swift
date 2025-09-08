import SwiftUI

struct ExportButton: View {
    @ObservedObject var viewModel: QRCodeViewModel
    @State private var isHoveringWithOption = false
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                let event = NSApp.currentEvent
                let withDialog = event?.modifierFlags.contains(.option) ?? false
                viewModel.exportToSVG(withDialog: withDialog)
            }) {
                HStack {
                    Image(systemName: isHoveringWithOption ? "square.and.arrow.down.on.square" : "square.and.arrow.down")
                    Text(isHoveringWithOption ? "Save As..." : "Export SVG")
                }
            }
            .controlSize(.large)
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