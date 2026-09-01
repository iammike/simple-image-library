//
//  ParentalGateView.swift
//  Simple Photo Viewer
//
//  Sheet shown after the press-and-hold. A correct answer opens Setup.
//  A large Cancel and swipe-to-dismiss ensure no one can get stuck here.
//

import SwiftUI

struct ParentalGateView: View {
    var onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var challenge = ParentalGateChallenge.random()
    @State private var entry = ""
    @State private var showError = false
    @FocusState private var isEntryFocused: Bool

    var body: some View {
        // The number pad has no Return key and covers most of a small iPhone, so the
        // content scrolls and the keyboard carries an explicit dismiss.
        ScrollView {
            content
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isEntryFocused = false }
            }
        }
    }

    private var content: some View {
        VStack(spacing: 24) {
            Text("Adult Check")
                .font(.title2).bold()

            Text("To open Setup, enter the answer:")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(challenge.prompt)
                .font(.system(size: 44, weight: .bold))

            TextField("Answer", text: $entry)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title)
                .frame(maxWidth: 160)
                .textFieldStyle(.roundedBorder)
                .focused($isEntryFocused)

            if showError {
                Text("Try again")
                    .foregroundColor(.red)
            }

            Button("Open Setup") { verify() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            Button("Cancel") { dismiss() }
                .controlSize(.large)
        }
        .padding(32)
    }

    private func verify() {
        isEntryFocused = false
        guard let value = Int(entry), challenge.isCorrect(value) else {
            showError = true
            entry = ""
            challenge = .random()
            return
        }
        onSuccess()
        dismiss()
    }
}
