import AppKit

enum SoundFX {
    enum Cue { case start, success, failure }

    static func play(_ cue: Cue) {
        let name: String
        switch cue {
        case .start:   name = "Pop"      // short click when recording begins
        case .success: name = "Tink"     // subtle acknowledge when text inserted
        case .failure: name = "Funk"     // error cue
        }
        NSSound(named: NSSound.Name(name))?.play()
    }
}
