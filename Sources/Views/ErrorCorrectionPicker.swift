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
                    Text(level.displayName)
                        .tag(level)
                }
            }
            .pickerStyle(.menu)
            .help("Higher levels allow more damage to the QR code while maintaining readability")
        }
    }
}