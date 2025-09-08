import SwiftUI

@main
struct QRCodeGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, idealWidth: 800, minHeight: 400, idealHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandGroup(after: .appInfo) {
                Button("Clear Text") {
                    NotificationCenter.default.post(name: Notification.Name("ClearText"), object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)
                
                Divider()
                
                Button("Save to Downloads") {
                    NotificationCenter.default.post(name: Notification.Name("SaveToDownloads"), object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)
                
                Button("Save As...") {
                    NotificationCenter.default.post(name: Notification.Name("SaveAs"), object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }
}