// RUN: %target-run-simple-swift(-Xfrontend -enable-experimental-concurrency)
import XCTest
@testable import TiqKit

final class TiqKitTests: XCTestCase {
    func testAsync() throws {
        XCTAssertEqual(3, awaitAsync(f: { Self.pausing { 1 + 2 } }))
        XCTAssertEqual(4, awaitAsync(f: { Self.pausing { 2 + 2 } }))
        XCTAssertEqual(5, awaitAsync(f: { Self.pausing { 1 + 4 } }))
    }

    func testAsyncInternal() throws {
        func one() async -> Int { 1 }
        func two() async -> Int { 2 }
        func three() async -> Int { 3 }

        func addUp() async -> Int {
            await one() + two() + three()
        }

        XCTAssertEqual(1+2+3, awaitAsync(f: { await addUp() }))
    }
}

public extension XCTestCase {
    /// Helper to introduce an artifical delay before returning the result of the closure
    static func pausing<T>(for interval: TimeInterval = TimeInterval.random(in: 0.0...1.0), then closure: () throws -> T) rethrows -> T {
        Thread.sleep(forTimeInterval: interval)
        return try closure()
    }

    func awaitingResult<T>(timeout: TimeInterval = 1.0, f: @escaping () async throws -> T) -> Result<T, Error> {
        awaitAsync {
            do {
                return .success(try await f())
            } catch {
                return .failure(error)
            }
        }
    }

    /// Shim for plugging XCTest into the async system
    func awaitAsync<T>(timeout: TimeInterval = 5.0, f: @escaping () async -> T) -> T! {
        let xpc = expectation(description: "await")
        var result: T!
        Self.ashim(f: f) {
            result = $0
            xpc.fulfill()
        }
        wait(for: [xpc], timeout: timeout)
        return result
    }

    @asyncHandler static private func ashim<T>(f: @escaping () async -> (T), completion: @escaping (T) -> ()) {
        completion(await(f()))
    }
}

#if canImport(FoundationNetworking)
import FoundationNetworking

extension TiqKitTests {
    func testNetworkSync() throws {
        func downloadURLsLikeWeUsedToDoInTheOldenDays() throws -> Int {
            let data1 = try Data(contentsOf: URL(string: "https://www.example.org")!)
            let data2 = try Data(contentsOf: URL(string: "https://www.example.net")!)
            let data3 = try Data(contentsOf: URL(string: "https://www.example.com")!)
            return data1.count + data2.count + data3.count
        }

        let sum = try downloadURLsLikeWeUsedToDoInTheOldenDays()

        XCTAssertGreaterThan(sum, 100, "page size check")
    }

    func testNetworkAsync() throws {
        /// Downloads the given URL using `URLSession.shared`
        func downloadURL(string: String) async throws -> Data {
            try await URLRequest(url: URL(string: string)!).fetch().data
        }

        func downloadURLs() async throws -> Int {
            let data1 = try await downloadURL(string: "https://www.example.org")
            let data2 = try await downloadURL(string: "https://www.example.net")
            let data3 = try await downloadURL(string: "https://www.example.com")
            return data1.count + data2.count + data3.count
        }

        let sum = awaitingResult { try await downloadURLs() }

        XCTAssertGreaterThan(try sum.get(), 100, "page size check")
    }
}

extension URLRequest {
    enum FetchError : Error {
        case noResponse
        case nonHTTPResponse(URLResponse)
        case unsuccessfulResponse(HTTPURLResponse, Data?)
    }

    /// Downloads the data for this request with the given session asynchronously, returning the response and data together
    func fetch(session: URLSession = .shared) async throws -> (response: HTTPURLResponse, data: Data) {
        try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: self) { (data, response, error) in
                if let error = error {
                    return continuation.resume(throwing: error)
                }

                guard let httpRes = response as? HTTPURLResponse else {
                    if let response = response {
                        return continuation.resume(throwing: FetchError.nonHTTPResponse(response))
                    } else {
                        return continuation.resume(throwing: FetchError.noResponse)
                    }
                }

                guard let data = data, httpRes.statusCode == 200 else {
                    return continuation.resume(throwing: FetchError.unsuccessfulResponse(httpRes, data))
                }

                print("returning data", data.count, "for", httpRes.url as Any, "on", Thread.current)
                return continuation.resume(returning: (httpRes, data))
            }.resume()
        }
    }
}
#endif // canImport(FoundationNetworking)
