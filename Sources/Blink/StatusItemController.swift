import AppKit
import BlinkCore

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    enum Command {
        case takeBreak, skip, pause(Pause), resume, settings, quit
    }

    enum Pause: String, CaseIterable {
        case thirtyMinutes = "30 Minutes"
        case oneHour = "1 Hour"
        case untilTomorrow = "Until Tomorrow"

        var deadline: Date {
            switch self {
            case .thirtyMinutes: .now.addingTimeInterval(30 * 60)
            case .oneHour: .now.addingTimeInterval(60 * 60)
            case .untilTomorrow: Calendar.current.startOfDay(for: .now.addingTimeInterval(24 * 60 * 60))
            }
        }
    }

    var onCommand: (Command) -> Void = { _ in }

    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let summaryItem = NSMenuItem()
    private var indicator: Indicator?
    private var summary = ""

    override init() {
        super.init()
        menu.autoenablesItems = false
        menu.delegate = self
        item.menu = menu
        item.button?.imagePosition = .imageLeading
        item.button?.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
    }

    func update(indicator: Indicator, countdown: String?, summary: String) {
        self.summary = summary
        summaryItem.title = summary
        if indicator != self.indicator {
            self.indicator = indicator
            item.button?.image = NSImage(systemSymbolName: indicator.symbol, accessibilityDescription: "Blink")
        }
        item.button?.title = countdown.map { " \($0)" } ?? ""
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        summaryItem.isEnabled = false
        menu.addItem(summaryItem)
        menu.addItem(.separator())
        menu.addItem(ActionItem("Take Break Now") { [weak self] in self?.onCommand(.takeBreak) })
        menu.addItem(ActionItem("Skip Next Break") { [weak self] in self?.onCommand(.skip) })

        let pause = NSMenu()
        pause.autoenablesItems = false
        for duration in Pause.allCases {
            pause.addItem(ActionItem(duration.rawValue) { [weak self] in self?.onCommand(.pause(duration)) })
        }
        pause.addItem(.separator())
        let resume = ActionItem("Resume") { [weak self] in self?.onCommand(.resume) }
        resume.isEnabled = indicator == .paused
        pause.addItem(resume)
        let pauseItem = NSMenuItem(title: "Pause", action: nil, keyEquivalent: "")
        pauseItem.submenu = pause
        menu.addItem(pauseItem)

        menu.addItem(ActionItem("Settings…", key: ",") { [weak self] in self?.onCommand(.settings) })
        menu.addItem(.separator())
        menu.addItem(ActionItem("Quit Blink", key: "q") { [weak self] in self?.onCommand(.quit) })
    }
}

@MainActor
private final class ActionItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String = "", handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        target = self
    }

    required init(coder: NSCoder) { fatalError() }

    @objc private func fire() { handler() }
}

private extension Indicator {
    var symbol: String {
        switch self {
        case .running: "eye"
        case .onBreak: "eye.fill"
        case .paused: "eye.slash"
        case .quiet: "eye.circle"
        }
    }
}
