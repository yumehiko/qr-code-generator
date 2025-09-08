# QR Code Generator for macOS

A native macOS application for generating QR codes with real-time preview and SVG export functionality.

## Features

- **Real-time QR Code Generation**: Automatically generates QR codes as you type (with 300ms debouncing)
- **Error Correction Levels**: Choose between Low (L), Medium (M), Quartile (Q), and High (H) error correction
- **Direct SVG Export**: Save QR codes directly to Downloads folder or choose a custom location
- **Native macOS Interface**: Built with SwiftUI following macOS design guidelines
- **Dark Mode Support**: Adapts to system appearance preferences

## Requirements

- macOS 11.0 (Big Sur) or later
- Xcode 13.0 or later (for building from source)

## Building from Source

### Using Swift Package Manager

1. Clone the repository:
```bash
git clone <repository-url>
cd qr-code-generator
```

2. Build the application:
```bash
swift build -c release
```

3. Run the application:
```bash
swift run
```

### Using the Build Script

1. Run the build script:
```bash
./build.sh
```

2. Open the generated app:
```bash
open "QR Code Generator.app"
```

## Usage

1. **Enter Text**: Type or paste text in the input field
2. **Automatic Generation**: QR code appears automatically as you type
3. **Adjust Error Correction**: Select error correction level (default: Medium)
4. **Save QR Code**: 
   - Click "Save to Downloads" to save directly
   - Hold Option (⌥) and click to choose save location
   - Use Cmd+S keyboard shortcut

## Architecture

The application follows MVVM architecture pattern:

- **Models**: Data structures for QR code information
- **Services**: QR generation and file export logic
- **ViewModels**: Business logic and state management
- **Views**: SwiftUI components for the user interface

## License

MIT License