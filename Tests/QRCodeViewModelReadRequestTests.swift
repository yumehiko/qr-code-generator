import XCTest
@testable import QRCodeGenerator

final class QRCodeViewModelReadRequestTests: XCTestCase {
    func testOlderImageRequestCannotReplaceNewerDropState() async {
        await MainActor.run {
            let viewModel = QRCodeViewModel()
            let firstRequest = viewModel.beginImageReadRequest()
            let secondRequest = viewModel.beginImageReadRequest()

            viewModel.reportImageSelectionFailure(TestError.failed, requestID: firstRequest)

            XCTAssertTrue(viewModel.isReading)
            XCTAssertNil(viewModel.readErrorMessage)

            viewModel.reportImageSelectionFailure(TestError.failed, requestID: secondRequest)

            XCTAssertFalse(viewModel.isReading)
            XCTAssertNotNil(viewModel.readErrorMessage)
        }
    }

    func testStaleURLDoesNotStartAReadAfterANewerRequest() async {
        await MainActor.run {
            let viewModel = QRCodeViewModel()
            let staleRequest = viewModel.beginImageReadRequest()
            let currentRequest = viewModel.beginImageReadRequest()

            viewModel.readQRCode(from: URL(fileURLWithPath: "/tmp/nonexistent-image"), requestID: staleRequest)

            XCTAssertTrue(viewModel.isReading)
            XCTAssertNil(viewModel.readErrorMessage)

            viewModel.reportImageSelectionFailure(TestError.failed, requestID: currentRequest)
            XCTAssertFalse(viewModel.isReading)
        }
    }

    private enum TestError: LocalizedError {
        case failed

        var errorDescription: String? { "Test image selection failed" }
    }
}
