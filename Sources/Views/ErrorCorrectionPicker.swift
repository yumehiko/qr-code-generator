import SwiftUI

struct ErrorCorrectionPicker: View {
    @Binding var selection: ErrorCorrectionLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Error Correction")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("", selection: $selection) {
                ForEach(ErrorCorrectionLevel.allCases) { level in
                    Text(level.rawValue)
                        .tag(level)
                        .accessibilityLabel(level.displayName)
                        .help(level.tooltip)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .help("Higher levels allow more damage to the QR code while maintaining readability")
            .accessibilityLabel("Error Correction")
        }
    }
}
