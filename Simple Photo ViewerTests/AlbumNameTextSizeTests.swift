import XCTest
@testable import Simple_Photo_Viewer

final class AlbumNameTextSizeTests: XCTestCase {
    func testDefaultIsMedium() {
        XCTAssertEqual(AlbumNameTextSize.defaultValue, .medium)
    }

    func testAllFourCasesExist() {
        XCTAssertEqual(AlbumNameTextSize.allCases, [.small, .medium, .large, .extraLarge])
    }

    func testPointSizesStrictlyIncrease() {
        let sizes = AlbumNameTextSize.allCases.map { $0.pointSize }
        XCTAssertEqual(sizes, sizes.sorted())
        XCTAssertEqual(Set(sizes).count, sizes.count, "Point sizes must be distinct")
    }

    func testMediumMatchesCurrentBodySize() {
        XCTAssertEqual(AlbumNameTextSize.medium.pointSize, 17)
    }

    func testRawValueRoundTrips() {
        for size in AlbumNameTextSize.allCases {
            XCTAssertEqual(AlbumNameTextSize(rawValue: size.rawValue), size)
        }
    }

    func testUnknownRawValueIsNil() {
        XCTAssertNil(AlbumNameTextSize(rawValue: "gigantic"))
    }

    func testDotScalesWithText() {
        XCTAssertLessThan(AlbumNameTextSize.small.recognitionDotSize,
                          AlbumNameTextSize.extraLarge.recognitionDotSize)
    }
}
