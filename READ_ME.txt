FLINKTEXT — Dictation for your Mac. Local, private, free.
==========================================================
(Deutsche Anleitung: siehe LIES_MICH.txt)

INSTALLATION
------------
1. Drag Flinktext.app into the "Applications" folder.
2. Launch Flinktext from the Applications folder.
   The app is signed with an Apple Developer ID and notarized by Apple:
   no Gatekeeper warning, no right-click trick needed.
3. On first launch the setup assistant guides you through three
   macOS permissions:
   - Microphone (for recording)
   - Accessibility (for the global hotkey and text at the cursor)
   - Input Monitoring (for hotkey detection)
   Confirm all three and pick a speech model — then you are ready.

HOW TO DICTATE
--------------
HOLD the key combination while speaking, release when done:
The text appears at the cursor, in any app.

The base key is always the RIGHT Option key (⌥, right of the
space bar). Hold it and add the second key:

  right ⌥ + ⇧ (Shift) ....... Raw: verbatim transcript, no post-processing
  right ⌥ + ⌃ (Control) ..... Polished: cleans up grammar and filler words
  right ⌥ + left ⌥ .......... Compose: say what should be written
  right ⌥ + ⌘ (Command) ..... Emoji: enriches the text with emojis

Keep both keys held while you speak. Releasing them starts
the processing.

Speech recognition runs 100 % locally on your device by default.
No account, no cloud, no telemetry.

UPGRADING FROM HANDSFREE (v0.9.x OR OLDER)?
-------------------------------------------
Flinktext is the new name of Handsfree. Three one-time notes:
1. Delete the old Handsfree.app from your Applications folder.
2. If you had stored API keys, the macOS keychain asks once per key.
   Enter your login password and click "ALWAYS ALLOW" (not just
   "Allow", or the prompt keeps returning). This is caused by the
   switch to the new Apple signature and happens only once.
3. Recording stays empty ("Recording empty") although permissions
   look active in System Settings? The entries still belong to the
   old Handsfree version. Run once in Terminal:
     tccutil reset Accessibility com.lighthouseconsultings.handsfree
     tccutil reset ListenEvent com.lighthouseconsultings.handsfree
     tccutil reset Microphone com.lighthouseconsultings.handsfree
   Then restart Flinktext and confirm the three fresh prompts.

QUESTIONS, FEEDBACK
-------------------
Web:    https://lighthouseconsultings.de/flinktext/
Code:   https://github.com/Lighthouse-Consultings/handsfree
Email:  addvalue@lighthouseconsultings.com

(c) 2026 Lighthouse Consultings. Open source, MIT license.
