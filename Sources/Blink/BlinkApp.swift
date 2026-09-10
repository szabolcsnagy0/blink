import AppKit

@main
enum BlinkApp {
    @MainActor static let controller = AppController()

    @MainActor static func main() {
        let app = NSApplication.shared
        app.delegate = controller
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
