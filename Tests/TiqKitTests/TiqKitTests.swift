// RUN: %target-run-simple-swift(-Xfrontend -enable-experimental-concurrency)
import XCTest
@testable import TiqKit

final class TiqKitTests: XCTestCase {
    func testAsync() throws {
        XCTAssertEqual(3, awaitAsync(f: { 1+2 }))
        XCTAssertEqual(4, awaitAsync(f: { 2+2 }))
        XCTAssertEqual(5, awaitAsync(f: { 1+4 }))
    }
}

public extension XCTestCase {
    /// Shim for plugging XCTest into the async system
    func awaitAsync<T>(timeout: TimeInterval = 1.0, f: @escaping () async -> T) -> T {
        let xpc = expectation(description: "await")
        var result: T!
        Self.dispatchAsync(f: f) {
            result = $0
            xpc.fulfill()
        }
        wait(for: [xpc], timeout: timeout)
        return result
    }

    @asyncHandler static private func dispatchAsync<T>(f: @escaping () async -> (T), completion: @escaping (T) -> ()) {
        completion(await(f()))
    }
}
