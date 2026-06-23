import XCTest
@testable import Simple_Photo_Viewer

final class ParentalGateTests: XCTestCase {
    func testAnswerIsSum() {
        XCTAssertEqual(ParentalGateChallenge(a: 7, b: 4).answer, 11)
    }

    func testPromptFormat() {
        XCTAssertEqual(ParentalGateChallenge(a: 7, b: 4).prompt, "7 + 4")
    }

    func testIsCorrectAcceptsSum() {
        XCTAssertTrue(ParentalGateChallenge(a: 7, b: 4).isCorrect(11))
    }

    func testIsCorrectRejectsWrongAnswer() {
        XCTAssertFalse(ParentalGateChallenge(a: 7, b: 4).isCorrect(10))
    }

    func testRandomOperandsAreInRange() {
        for _ in 0..<200 {
            let c = ParentalGateChallenge.random()
            XCTAssertTrue((1...9).contains(c.a))
            XCTAssertTrue((1...9).contains(c.b))
        }
    }
}
