import XCTest
@testable import FluentQuery

final class FluentQueryTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(FluentQuery().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
