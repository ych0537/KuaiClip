import AppKit

// Custom NSPanel that can become key even with borderless style.
final class PopupPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override func mouseDown(with event: NSEvent) {
        performDrag(with: event)
    }
}
