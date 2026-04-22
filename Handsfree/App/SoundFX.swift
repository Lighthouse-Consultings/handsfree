import AppKit

enum SoundFX {
    enum Cue { case start, success, failure }

    static func play(_ cue: Cue) {
        // Only start cue plays audio — success/failure are silent by user preference.
        guard cue == .start else { return }
        NSSound(named: NSSound.Name("Purr"))?.play()
    }
}
