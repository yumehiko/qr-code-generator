import SwiftUI
import AppKit

struct MacTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .systemFont(ofSize: 13)
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = font
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacTextEditor
        
        init(_ parent: MacTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

struct TextInputView: View {
    @Binding var text: String
    var error: QRCodeError?
    
    private var hasError: Bool {
        if case .textTooLong = error {
            return true
        }
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Text Input")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Type or paste text here...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .allowsHitTesting(false)
                }
                
                MacTextEditor(text: $text)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(hasError ? Color.red : Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(6)
            }
            
            HStack {
                Text("\(text.count) characters")
                    .font(.caption2)
                    .foregroundColor(hasError ? .red : .secondary)
                
                if hasError {
                    Label("Exceeds capacity", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
    }
}