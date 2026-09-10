# Blink

macOS menu bar break reminder. Personal project, single user, no dependencies.

## Commands

    make app      # build/Blink.app, ad-hoc signed
    make install  # copy to /Applications
    make test     # scheduler tests
    make icon     # regenerate Resources/AppIcon.icns

Plain `swift test` fails: the Command Line Tools do not expose Testing.framework on the default search paths. `make test` passes the flags that find it.

## Architecture

- `BlinkCore` holds every timing decision as a value type. No AppKit, no timers, no system calls: events in, a new state and a `Presentation` out. New behaviour goes here first, with a test.
- `Blink` is the shell. It ticks the scheduler once a second, feeds it signals, and renders whatever `Presentation` says. It decides nothing.
- One monitor per signal in `Signals/`. Lock is notification driven, the rest are polled on the tick, and disabled rules are not polled at all.

## Constraints

- Swift 6 strict concurrency, minimum macOS 15, SwiftPM only. No Xcode project, no packages.
- No permission prompts, ever. Camera and microphone use is read through "running somewhere" device properties. Anything needing TCC or Accessibility is out of scope.
- Not sandboxed, not notarized, ad-hoc signed.
- Break windows must keep `sharingType = .none` so they never appear in a screen share.

## Deliberately not built

Sound, pre-warning before a break, strict mode without a skip, long breaks, statistics, global hotkeys, Focus integration, per-app screen-share detection, active hours, auto-update, localization, notarization. Do not add these unasked.

## Unverified

- Capture exclusion during a real Teams or Slack share.
- Camera and microphone detection during an actual call.
- Overlay above a fullscreen Space.
- `SMAppService` registration once installed in /Applications.
