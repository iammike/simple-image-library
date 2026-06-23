//
//  ParentalGate.swift
//  Simple Photo Viewer
//
//  A simple arithmetic challenge used to keep Setup out of a child's reach.
//

import Foundation

struct ParentalGateChallenge: Equatable {
    let a: Int
    let b: Int

    var answer: Int { a + b }
    var prompt: String { "\(a) + \(b)" }

    func isCorrect(_ input: Int) -> Bool { input == answer }

    /// A fresh challenge with single-digit operands.
    static func random() -> ParentalGateChallenge {
        ParentalGateChallenge(a: Int.random(in: 1...9), b: Int.random(in: 1...9))
    }
}
