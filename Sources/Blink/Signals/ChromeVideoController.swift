import AppKit
import BlinkCore
import CoreServices

/// Pauses and resumes Chrome video by running a script in the active tab of each window, through
/// Chrome's AppleScript `execute javascript`. Unlike the play/pause key this does not toggle: the
/// page reports the video's real state, so a paused video is never started. It needs Automation
/// of Chrome and Chrome's View > Developer > Allow JavaScript from Apple Events.
@MainActor
final class ChromeVideoController {
    nonisolated static let bundleID = "com.google.Chrome"

    private var pause = VideoPause()
    /// Names the break whose pause marked the videos, so marks left by a break whose resume never
    /// ran (Blink quit mid-break) are never mistaken for this one's.
    private var token = ""

    func render(overlay: Bool, enabled: Bool) {
        switch pause.render(overlay: overlay, enabled: enabled) {
        case .pause:
            token = String(Int(Date.now.timeIntervalSince1970 * 1000))
            run(Self.pauseVideo(token: token))
        case .resume:
            run(Self.resumeVideo(token: token))
        case nil:
            break
        }
    }

    /// Asks for Automation of Chrome now, from Settings, rather than at the first break where the
    /// prompt would sit behind the overlay. Chrome has to be running for macOS to ask.
    static func requestPermission() {
        Task.detached {
            let target = NSAppleEventDescriptor(bundleIdentifier: bundleID)
            guard let desc = target.aeDesc else { return }
            _ = AEDeterminePermissionToAutomateTarget(desc, typeWildCard, typeWildCard, true)
        }
    }

    /// Fullscreen is judged in the page: the Fullscreen API for a player's own fullscreen button,
    /// or a viewport filling the screen for a fullscreen window.
    private static func pauseVideo(token: String) -> String {
        """
        (() => {
          const fullscreen = document.fullscreenElement
            || (innerWidth === screen.width && innerHeight === screen.height);
          if (!fullscreen) return;
          for (const video of document.querySelectorAll('video')) {
            if (!video.paused && !video.ended) {
              video.pause();
              video.dataset.blinkPaused = '\(token)';
            }
          }
        })()
        """
    }

    /// Plays only what this break paused and is still paused, and drops every mark.
    private static func resumeVideo(token: String) -> String {
        """
        (() => {
          for (const video of document.querySelectorAll('video[data-blink-paused]')) {
            const ours = video.dataset.blinkPaused === '\(token)';
            delete video.dataset.blinkPaused;
            if (ours && video.paused) video.play().catch(() => {});
          }
        })()
        """
    }

    /// Skipped when Chrome is not running, since addressing it would launch it.
    private func run(_ javascript: String) {
        guard NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleID).isEmpty == false else { return }
        let source = """
            tell application id "\(Self.bundleID)"
              with timeout of 2 seconds
                repeat with chromeWindow in windows
                  try
                    execute active tab of chromeWindow javascript "\(javascript.replacingOccurrences(of: "\n", with: " "))"
                  end try
                end repeat
              end timeout
            end tell
            """
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }
}
