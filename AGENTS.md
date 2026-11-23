# Blink

macOS menu bar break reminder. Personal project, single user, no dependencies.

## Commands

    make app      # build/Blink.app, signed with the local identity, else ad-hoc
    make install  # quit Blink, copy to /Applications, relaunch
    make cert     # one-time: create and trust the local signing identity
    make test     # scheduler tests
    make icon     # regenerate Resources/AppIcon.icns

Plain `swift test` fails: the Command Line Tools do not expose Testing.framework on the default search paths. `make test` passes the flags that find it.

## Architecture

- `BlinkCore` holds every timing decision as a value type. No AppKit, no timers, no system calls: events in, a new state and a `Presentation` out. New behaviour goes here first, with a test.
- `Blink` is the shell. It ticks the scheduler once a second, feeds it signals, and renders whatever `Presentation` says. It decides nothing.
- One monitor per signal in `Signals/`. Lock is notification driven, the rest are polled on the tick, and disabled rules are not polled at all.

## Constraints

- Swift 6 strict concurrency, minimum macOS 15, SwiftPM only. No Xcode project, no packages.
- One permission, opt-in: pausing Chrome video during an overlay needs Automation of Chrome (plus Chrome's "Allow JavaScript from Apple Events"), and asks only when the option is turned on. It runs a script in the page that pauses only playing fullscreen video and resumes only what it paused; never go back to the play/pause key, which toggles and so starts paused video. Nothing else may require TCC, Automation or Accessibility, and camera and microphone use is still read through "running somewhere" device properties rather than a prompt.
- Not sandboxed, not notarized. Signed with the self-signed "Blink Local Signing" identity from `make cert` so the Automation grant survives rebuilds; ad-hoc without it, which loses the grant on every install.
- Break windows must keep `sharingType = .none` so they never appear in a screen share.

## Deliberately not built

Sound, pre-warning before a break, strict mode without a skip, long breaks, statistics, global hotkeys, Focus integration, per-app screen-share detection, active hours, auto-update, localization, notarization. Do not add these unasked.

