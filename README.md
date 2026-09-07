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

## Verification

The supported local verification commands are:

```bash
./run_tests.sh      # runs swift test
swift build -c release
```

`swift test` validates QR image generation, SVG conversion, input limits, and
the main-actor ViewModel state. The tests do not open save dialogs or write to
the user's Downloads directory. To check the bundled macOS application
manually, run `./build.sh` and open `QR Code Generator.app`.

The repository requires macOS 11 or later. Building from source requires a
Swift toolchain supplied by Xcode 13 or later.

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

## Development workflow

作業状態の正本は GitHub Issues です。設計資料（`.spec-workflow/specs/`）は要件・設計の参照として保持し、作業の開始・完了・保留は対応する Issue に記録します。作業開始前に既存Issueを確認し、重複するIssueを作成しないでください。

Issue 単位で実装担当（Terra/Luna）が変更を作成し、PR を提出します。別担当（Sol/Terra）が受入条件、テスト、PR の HEAD を確認し、必要な修正後に再レビューしてから通常の保護された手順でマージします。

Issue や PR に秘密の実値、認証情報、個人環境の絶対パスを記載しないでください。提出前に `swift test` または `./run_tests.sh`、および変更に応じたビルド確認を実行してください。

## License

MIT License
