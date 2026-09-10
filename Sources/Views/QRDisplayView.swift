import SwiftUI

struct QRDisplayView: View {
    let qrImage: NSImage?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if let qrImage {
                Image(nsImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.1), radius: 8, x: 0, y: 4)
            } else {
                Image(systemName: "qrcode")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary.opacity(0.3))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
        }
    }
}
