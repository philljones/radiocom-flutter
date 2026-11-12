import AppIntents
import UIKit

@available(iOS 17.0, *)
struct PlayAberRadioIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Play Aber Radio"
    static let description = IntentDescription("Start the Aber Radio live stream.")
    static let openAppWhenRun = false
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let app = UIApplication.shared.delegate as? AppDelegate else {
            throw RadioPlaybackError.unavailable
        }
        let started: Bool = await withCheckedContinuation { continuation in
            app.startLivePlayback(source: "siri") { success in
                continuation.resume(returning: success)
            }
        }
        guard started else { throw RadioPlaybackError.unavailable }
        return .result()
    }
}

private enum RadioPlaybackError: LocalizedError {
    case unavailable

    var errorDescription: String? { "Couldn't start Aber Radio. Please try again." }
}

@available(iOS 17.0, *)
struct AberRadioShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayAberRadioIntent(),
            phrases: [
                "Play \(.applicationName)",
                "Listen to \(.applicationName)",
                "Play \(.applicationName) live"
            ],
            shortTitle: "Play Live",
            systemImageName: "play.circle"
        )
    }
}
