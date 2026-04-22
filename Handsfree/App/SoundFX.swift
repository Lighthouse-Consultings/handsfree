import AppKit

enum SoundFX {
    enum Cue { case start, success, failure }

    static func play(_ cue: Cue) {
        let name: String
        switch cue {
        case .start:   name = "Purr"     // soft purr when recording begins
        case .success: name = "Hero"     // two-note ascending chime on success
        case .failure: name = "Basso"    // soft low cue for errors
        }
        NSSound(named: NSSound.Name(name))?.play()
    }
}
