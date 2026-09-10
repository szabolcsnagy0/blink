# Blink — plan

A native macOS menu bar app that reminds you to look away from the screen at a configured interval. Lightweight, simple, professional. Personal use, single user.

Bundle identifier: `io.github.szabolcsnagy0.blink`. Repository: `szabolcsnagy0/blink`.

## Decisions

### Behaviour

- **Interval timer.** Every N minutes, take a break of S seconds. Defaults: 20 min / 20 s (the 20-20-20 rule). Both configurable.
- **Active time only.** The timer pauses while the screen is locked or the display is asleep. It resumes where it left off on unlock.
- **Natural breaks count.** If the user is idle (no keyboard/mouse input) for longer than the break length, the break is considered taken and the interval restarts on the next input.
- **No pre-warning, no sound, no statistics, one break type.**
- **Skippable.** Every break can be skipped with a click or Esc. There is no strict mode.
- **Manual pause.** Pause for 30 min, 1 h, or until tomorrow. Resume from the menu at any time.

### Presentation

Two display modes, selected in settings. Both are excluded from screen capture via `NSWindow.sharingType = .none`, so meeting participants never see them.

- **Dim overlay.** A translucent dark panel over every display, above everything including fullscreen apps, with a countdown ring, the text "Look at something far away", and a Skip button. Esc skips. Ends automatically when the countdown reaches zero.
- **Pill.** A small floating capsule below the menu bar on the main display with the countdown and a Skip button. Never takes focus. Click to skip.

### Suppression rules

Each rule has its own toggle in settings.

| Signal | Effect | Source |
|---|---|---|
| Screen locked / display asleep | Timer paused | `com.apple.screenIsLocked` distributed notification, `NSWorkspace.screensDidSleepNotification` |
| Idle longer than break length | Break counted as taken | `CGEventSource.secondsSinceLastEventType` |
| Camera or microphone in use by any app ("in a call") | Break shown as pill instead of overlay | CoreMediaIO `kCMIODevicePropertyDeviceIsRunningSomewhere`, CoreAudio `kAudioDevicePropertyDeviceIsRunningSomewhere` |
| Frontmost app is fullscreen | Break shown as pill instead of overlay | `CGWindowListCopyWindowInfo` bounds of frontmost app's windows vs screen frame |
| Manual pause | Timer paused until the chosen time | Menu |

Not built in v1: Focus / Do Not Disturb detection (no public API), app-specific screen-share detection (heuristics per app, no public API). The `sharingType` exclusion covers the visible-to-others problem; the in-call rule covers the do-not-interrupt problem.

### Menu bar

- Icon only: an SF Symbol eye. Variants for running, on break, paused, and quiet (pill-only because of a suppression rule). Optional countdown text next to the icon, off by default.
- Menu items: next break in `mm:ss`, Take Break Now, Skip Next Break, Pause ▸ (30 min, 1 h, Until Tomorrow, Resume), Settings…, Launch at Login, Quit.

### Settings window

One SwiftUI form:

- Interval (minutes), break length (seconds)
- Break style: Overlay / Pill
- Show countdown in menu bar
- Suppression toggles: pause when locked, count idle as break, pill during calls, pill during fullscreen apps
- Launch at login

Settings live in `UserDefaults` under the app's bundle identifier.

## Technical setup

- **Swift 6**, strict concurrency. Minimum macOS 15.
- **SwiftPM only, no Xcode.** Command Line Tools provide `swift build`, `swift test`, `codesign`, `iconutil`. A `Makefile` assembles `build/Blink.app` from the binary, a hand-written `Info.plist`, and the icon, then ad-hoc signs it. `make install` copies it to `/Applications`.
- **AppKit for the shell**: `NSStatusItem` + `NSMenu`, `NSPanel` for overlay and pill. **SwiftUI for content**: settings form, overlay view, pill view, hosted via `NSHostingView`.
- **Not sandboxed, not notarized**, ad-hoc signed. Launch at login via `SMAppService.mainApp`.
- `Info.plist`: `LSUIElement = true` (no Dock icon), `LSMinimumSystemVersion = 15.0`, `NSHighResolutionCapable`, `CFBundleIconFile`.

### Layout

```
blink/
  Package.swift
  Makefile
  PLAN.md
  README.md
  Sources/
    BlinkCore/                 # library, no AppKit. Pure logic, fully unit tested.
      Scheduler.swift          # state machine
      Settings.swift           # value type + defaults keys
      Suppression.swift        # Reason enum, Set<Reason> -> effect
    Blink/                     # executable, the app
      BlinkApp.swift           # @main, NSApplication setup
      AppController.swift      # owns scheduler, timer tick, wires signals to UI
      StatusItemController.swift
      Presentation/
        OverlayWindowController.swift
        OverlayView.swift
        PillWindowController.swift
        PillView.swift
      Settings/
        SettingsWindowController.swift
        SettingsView.swift
      Signals/
        LockMonitor.swift
        IdleMonitor.swift
        CallMonitor.swift      # CoreMediaIO + CoreAudio
        FullscreenMonitor.swift
      LoginItem.swift
    Resources/
      Info.plist
      AppIcon.icns
  Tests/
    BlinkCoreTests/
      SchedulerTests.swift
  Spikes/                      # throwaway executables, deleted once answered
```

### Scheduler

A value type driven entirely by events, with no timers or system calls inside. The app layer ticks it once per second and forwards signal changes.

States: `running(remaining)`, `onBreak(remaining)`, `paused(until)`, `suspended(reason)` (locked/asleep).

Events: `tick(now, idleSeconds)`, `suppressionChanged(Set<Reason>)`, `takeBreakNow`, `skip`, `pause(until)`, `resume`, `settingsChanged`.

Outputs: the new state plus a `Presentation` value (`none`, `overlay(remaining)`, `pill(remaining)`) computed from state and active reasons. The UI renders whatever `Presentation` says and nothing else. Tests use a fake clock and assert on state transitions: interval elapses → break starts; idle > break length → interval restarts; lock pauses and unlock resumes with the same remaining; in-call downgrades overlay to pill; skip ends break and restarts interval; pause until a time then auto-resume.

### Presentation windows

- Overlay: one `NSPanel` per `NSScreen`, `level = .screenSaver`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`, `sharingType = .none`, non-opaque, `styleMask = [.borderless, .nonactivatingPanel]`. To accept Esc, the main-screen panel becomes key and the previously active app is re-activated when the overlay closes. Rebuilt on `NSApplication.didChangeScreenParametersNotification`.
- Pill: one `NSPanel`, `level = .floating`, `.nonactivatingPanel`, `sharingType = .none`, positioned top-right under the menu bar with a fixed inset. Click to skip.

## Spikes

Each spike is a tiny executable in `Spikes/` with a pass/fail criterion. Run before writing the real app. Delete afterwards.

1. **Capture exclusion.** Show a panel with `sharingType = .none`, share the screen in Microsoft Teams (and Slack huddle) on macOS 26. Pass: panel is visible locally, absent in the shared feed. If it fails, fall back to detecting the share and forcing pill mode.
2. **Call detection without permission prompts.** Query CoreMediaIO / CoreAudio "running somewhere" while a Teams call is active. Pass: true during the call, false after, and no camera/mic TCC prompt appears. If a prompt appears, keep mic-only via CoreAudio or drop the rule.
3. **Overlay above fullscreen apps.** Put Safari in a fullscreen Space, trigger the overlay. Pass: overlay appears on top on every display.
4. **Bundle from Makefile.** `make app && open build/Blink.app`. Pass: status item appears, no Dock icon, `SMAppService` registration succeeds after `make install`.
5. **Idle seconds.** `CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)` returns growing values while hands-off. Pass: matches a stopwatch within a second.

## Milestones

- **M0 Spikes.** All five answered. Adjust the plan if 1 or 2 fail.
- **M1 Core.** `BlinkCore` scheduler + settings + tests green with `swift test`.
- **M2 Shell.** Status item, menu, overlay, pill, Take Break Now, Skip. Hard-coded settings. Usable end to end.
- **M3 Signals and settings.** Lock, idle, call, fullscreen monitors. Settings window. Manual pause. Launch at login.
- **M4 Finish.** App icon, Makefile `install`, README with build instructions, first tagged release.

## Deferred

Long breaks, statistics, global hotkeys (Accessibility permission), Focus integration, per-app share detection, active hours, auto-update, localization, strict mode, notarization.
