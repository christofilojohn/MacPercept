# Percept: App Store Listing

Copy for App Store Connect after the rename from "Mac Vision Tools" (rejected under Guideline 5.2.5 for resembling Apple Vision Pro).

Rules this copy follows: no "Mac", "Vision", "Apple", "Pro", or "i-" prefixed words in the **name, subtitle, keywords, or screenshot captions**. Referring to the platform descriptively in the description ("for macOS") is allowed.

## Name (30 max)

`Percept: On-Device AI Detector` (30)

Fallback if the name is taken: `Percept – Local AI Detection` (28)

## Subtitle (30 max)

`Live object & face detection` (28)

## Keywords (100 max, comma-separated, no spaces)

`object detection,coreml,camera,privacy,focus timer,emotion,face,menu bar,ai,ml,screen,offline` (93)

## Promotional text (170 max)

Real-time AI detection for your camera and screen, right from the menu bar. Everything runs on device: no accounts, no analytics, no uploads.

## Description

Percept brings real-time computer vision to your menu bar. Point it at your camera or any part of your screen and see what it detects, entirely on device.

FOUR MODES
• Standard Detection: spot 80 everyday object classes (people, laptops, phones, cups and more) with live bounding boxes in a window or a transparent overlay.
• Emotion Vibes: find faces and classify seven expressions, with a short rolling history.
• Privacy Guard: count the people in view and start the screen saver when too many are watching.
• Focus Timer: head-pose tracking that only counts minutes while you are actually looking at your work.

BRING YOUR OWN MODEL
Use the bundled models or select any Core ML detector or classifier (.mlmodel, .mlpackage, .mlmodelc) to experiment with your own.

PRIVATE BY DESIGN
• All inference runs locally with Core ML.
• Camera and screen frames are never saved or uploaded.
• No accounts, analytics, ads, or tracking.

CONTROLS
Choose camera or screen input, window or overlay display, frame rate (10, 30, 60 or Max) and confidence threshold, all from one compact panel.

Privacy Guard starts the screen saver. To lock the screen as well, turn on "Require password immediately after screen saver begins" in System Settings.

## What's New

Percept is the new name for this app. New icon, refreshed design, and the frame-rate picker now fits the panel.

## Notes for App Review

The app was previously submitted as "Mac Vision Tools" and rejected under 5.2.5. It has been renamed to "Percept" everywhere: the bundle display name, the in-app title, the window titles, the camera permission string, the screenshots, and the metadata. Apple trademarks no longer appear in the name, subtitle, keywords, or screenshots.

How to test: click the eye icon in the menu bar, choose a mode, leave Source on Camera, and press Start. Allow camera access when asked. Screen input needs Screen Recording permission. Focus Timer needs no model. Privacy Guard only starts the screen saver when 2 or more people are in view.

## URLs

- Privacy policy: `https://perceptapp.pages.dev/privacy/` (Cloudflare Pages project `perceptapp`). The old `macvisiontools.pages.dev` project stays up so build 2 and older links keep working.
- Marketing URL (optional): `https://perceptapp.pages.dev/`
- Support URL: `https://github.com/christofilojohn/MacPercept/issues`

## Screenshots

`app-store/screenshots/en-US/mac-2880x1800/01–05*.png`: 2880×1800, RGB, no alpha. Regenerate with the commands in the README.
