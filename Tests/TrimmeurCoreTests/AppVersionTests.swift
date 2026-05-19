import XCTest
@testable import TrimmeurCore

final class AppVersionTests: XCTestCase {
    func testQuitTitleIncludesVersionWhenAvailable() {
        XCTAssertEqual(
            AppVersion.quitMenuItemTitle(appName: "Trimmeur", version: "1.0"),
            "Quit Trimmeur 1.0"
        )
    }

    func testQuitTitleOmitsVersionWhenUnavailable() {
        XCTAssertEqual(
            AppVersion.quitMenuItemTitle(appName: "Trimmeur", version: " "),
            "Quit Trimmeur"
        )
    }
}
