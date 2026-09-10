# Blink

A macOS menu bar app that reminds you to look away from the screen. Every 20 minutes, rest your eyes for 20 seconds. Both numbers are configurable.

## Behaviour

- The break shows as a dimmed full screen overlay, or as a small pill under the menu bar. Both are excluded from screen capture, so meeting participants never see them.
- Any break can be skipped with a click or Esc.
- The timer pauses while the screen is locked or the display sleeps, and resumes where it left off.
- Being idle longer than a break counts as a break taken.
- While the camera or microphone is in use, or the frontmost app is fullscreen, the break shows as a pill instead of an overlay.
- Manual pause for 30 minutes, an hour, or until tomorrow.

Every rule has a toggle in Settings. Nothing leaves the machine, and no permissions are requested.

## Build

Requires macOS 15 and the Xcode Command Line Tools. No Xcode, no dependencies.

```
make app      # build/Blink.app
make install  # copy it to /Applications
make test     # scheduler unit tests
make icon     # regenerate the app icon
```

The app is ad-hoc signed and not notarized: on first launch, open it from Finder with right click > Open.

## Layout

- `Sources/BlinkCore` — the scheduler. All timing policy as a value type driven by events, with no timers or system calls, so it is fully unit tested.
- `Sources/Blink` — the app. AppKit for the status item and panels, SwiftUI for their content, one monitor per system signal.
