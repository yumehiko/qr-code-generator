# QR Code Generator for macOS

QR Code Generator is a native macOS app for creating QR codes and reading QR
codes from image files. It works locally on your Mac and supports SVG export.

## Requirements

- macOS 11 (Big Sur) or later
- Xcode 14 or later when building from source

## Install and launch

When a signed release is available, download the universal `.dmg` from the
[GitHub Releases page](https://github.com/yumehiko/qr-code-generator/releases),
open it, and drag **QR Code Generator.app** to Applications. The accompanying
`SHA256SUMS.txt` file lets you verify the download. A release DMG supports both
Apple silicon and Intel Macs running macOS 11 or later.

To build from source, clone the repository and run:

```bash
git clone https://github.com/yumehiko/qr-code-generator.git
cd qr-code-generator
scripts/build-app.sh
open "dist/QR Code Generator.app"
```

You can also run the app directly during development:

```bash
swift run
```

## Create a QR code

1. Enter or paste text into the input field.
2. The preview updates automatically.
3. Choose an error-correction level with the L, M, Q, or H segmented control.
   Medium is the default.
4. Use the **Copy** and **Export SVG** controls next to the preview. Export saves an SVG file to Downloads. Option-click it to
   choose another save location. Command-E exports to Downloads; choose
   **Save As...** from the app menu or press Shift-Command-E to choose a
   location.

## Read a QR code from an image

1. Click **Read Image** in the toolbar, **Select Image...** in the reader
   section, or drop an image file onto the outlined reader area.
2. Choose an image containing one or more QR codes.
3. Review each detected value and use its copy button when needed.

When several files are dropped, the app reads the first file only. Starting a
new selection or drop replaces the older read request, so an earlier failure or
result cannot overwrite the current result.

The app keeps image reading on your Mac. URLs are displayed as text and are not
opened automatically.

## Development

Build, test, packaging, and contribution guidance is in
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the [MIT License](LICENSE). The license covers
the application source and repository-owned icon assets, including the bundled
ICNS icon and app icon asset catalog.
