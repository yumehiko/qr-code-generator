# Tasks Document

- [x] 1. Initialize Xcode project structure
  - File: QRCodeGenerator.xcodeproj
  - Create new macOS app project with SwiftUI
  - Configure project settings for macOS 11.0+
  - Set up bundle identifier and app metadata
  - Purpose: Establish project foundation
  - _Requirements: 4.0_

- [x] 2. Create data models
  - File: Sources/Models/QRCodeData.swift
  - Define QRCodeData struct with text, correction level, and generation timestamp
  - Define ErrorCorrectionLevel enum with L/M/Q/H cases
  - Define ExportResult struct for file operations
  - Purpose: Establish data structures for QR code operations
  - _Requirements: 1.1, 2.1_

- [x] 3. Implement QR code generation service
  - File: Sources/Services/QRCodeGenerator.swift
  - Create QRCodeGenerator class with CoreImage integration
  - Implement generate(from:correctionLevel:) method using CIFilter
  - Add convertToSVG(from:) method for SVG conversion
  - Purpose: Core QR code generation functionality
  - _Leverage: CoreImage.CIFilter, CoreGraphics_
  - _Requirements: 1.1, 2.1_

- [x] 4. Create file export service
  - File: Sources/Services/FileExportService.swift
  - Implement saveToDownloads(content:filename:) method
  - Implement saveWithDialog(content:suggestedName:) method
  - Add timestamp-based filename generation
  - Purpose: Handle file saving operations
  - _Leverage: Foundation.FileManager, AppKit.NSSavePanel_
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 5. Build main view model
  - File: Sources/ViewModels/QRCodeViewModel.swift
  - Create ObservableObject with @Published properties
  - Implement text input handling with Combine debouncing (300ms)
  - Add generateQRCode() method connecting to QRCodeGenerator
  - Add exportToSVG() method using FileExportService
  - Purpose: Business logic and state management
  - _Leverage: Combine.Publishers, QRCodeGenerator, FileExportService_
  - _Requirements: 1.1, 1.2, 3.1_

- [x] 6. Create text input view component
  - File: Sources/Views/TextInputView.swift
  - Implement SwiftUI TextEditor with binding to view model
  - Add placeholder text when empty
  - Configure proper styling and padding
  - Purpose: User text input interface
  - _Leverage: SwiftUI.TextEditor_
  - _Requirements: 1.1, 1.3_

- [x] 7. Build QR code display view
  - File: Sources/Views/QRDisplayView.swift
  - Create SwiftUI view to display NSImage
  - Add empty state placeholder
  - Implement auto-scaling to maintain aspect ratio
  - Purpose: Display generated QR codes
  - _Leverage: SwiftUI.Image_
  - _Requirements: 1.1, 1.2_

- [x] 8. Implement error correction picker
  - File: Sources/Views/ErrorCorrectionPicker.swift
  - Create segmented control for L/M/Q/H selection
  - Add tooltips explaining each level
  - Bind to view model's correction level property
  - Purpose: Allow users to select error correction level
  - _Leverage: SwiftUI.Picker_
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 9. Create export button component
  - File: Sources/Views/ExportButton.swift
  - Implement primary save button for default Downloads folder
  - Add Option-click detection for save dialog
  - Display confirmation message after successful save
  - Purpose: File export user interface
  - _Leverage: SwiftUI.Button, NSEvent modifiers_
  - _Requirements: 3.1, 3.2, 3.4, 3.5_

- [x] 10. Build controls view container
  - File: Sources/Views/ControlsView.swift
  - Combine ErrorCorrectionPicker and ExportButton
  - Add proper layout and spacing
  - Ensure consistent styling
  - Purpose: Container for control elements
  - _Leverage: ErrorCorrectionPicker, ExportButton_
  - _Requirements: 2.1, 3.1_

- [x] 11. Assemble main content view
  - File: Sources/Views/ContentView.swift
  - Create main window layout with TextInputView, QRDisplayView, and ControlsView
  - Configure window size constraints
  - Add @StateObject for QRCodeViewModel
  - Purpose: Main application interface
  - _Leverage: All view components, QRCodeViewModel_
  - _Requirements: 4.1, 4.2, 4.5_

- [x] 12. Configure app entry point
  - File: Sources/QRCodeGeneratorApp.swift
  - Set up @main App struct
  - Configure window group with ContentView
  - Add app menu customization
  - Purpose: Application lifecycle management
  - _Leverage: SwiftUI.App_
  - _Requirements: 4.1, 4.3_

- [x] 13. Add error handling utilities
  - File: Sources/Utilities/ErrorHandler.swift
  - Create error alert presentation helper
  - Add capacity validation for QR code text
  - Implement user-friendly error messages
  - Purpose: Centralized error handling
  - _Requirements: 1.5, 3.5_

- [x] 14. Implement dark mode support
  - File: Sources/Views/ContentView.swift (modify)
  - Add @Environment(\.colorScheme) detection
  - Update all views to use semantic colors
  - Test appearance in both light and dark modes
  - Purpose: Support system appearance preferences
  - _Leverage: SwiftUI environment values_
  - _Requirements: 4.4_

- [x] 15. Add keyboard shortcuts
  - File: Sources/Views/ContentView.swift (modify)
  - Implement Cmd+S for save operation
  - Add Cmd+Q for quit (standard)
  - Configure keyboard modifiers
  - Purpose: Enhanced keyboard accessibility
  - _Leverage: SwiftUI keyboard shortcuts_
  - _Requirements: 4.3_

- [x] 16. Create app icon and assets
  - File: Resources/Assets.xcassets
  - Design and add app icon
  - Configure icon for all required sizes
  - Add any additional image assets
  - Purpose: Visual identity and branding
  - _Requirements: 4.1_

- [x] 17. Write unit tests for services
  - File: Tests/Services/QRCodeGeneratorTests.swift
  - Test QR generation with various inputs
  - Test SVG conversion
  - Test error correction levels
  - Purpose: Ensure service reliability
  - _Leverage: XCTest_
  - _Requirements: All service methods_

- [ ] 18. Write UI tests
  - File: UITests/QRCodeGeneratorUITests.swift
  - Test text input and automatic generation
  - Test error correction level changes
  - Test save operations
  - Purpose: Validate user interactions
  - _Leverage: XCUITest_
  - _Requirements: All user stories_

- [ ] 19. Configure build settings
  - File: QRCodeGenerator.xcodeproj
  - Set up code signing
  - Configure release build optimizations
  - Add necessary entitlements for file access
  - Purpose: Prepare for distribution
  - _Requirements: 4.1_

- [ ] 20. Final integration and testing
  - File: All components
  - Run full application flow tests
  - Verify all requirements are met
  - Fix any integration issues
  - Purpose: Ensure complete functionality
  - _Requirements: All_