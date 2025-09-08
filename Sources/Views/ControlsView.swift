import SwiftUI

struct ControlsView: View {
    @Binding var errorCorrectionLevel: ErrorCorrectionLevel
    @ObservedObject var viewModel: QRCodeViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            ErrorCorrectionPicker(selection: $errorCorrectionLevel)
            
            ExportButton(viewModel: viewModel)
        }
    }
}