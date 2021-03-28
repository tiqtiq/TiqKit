import XCTest
@testable import TiqKit

final class TiqKitTests: XCTestCase {
    func testTiqKitModule() {
        XCTAssertEqual(TiqKitModule().internalTiqKitData, "Hi TiqKit!")
    }
}
