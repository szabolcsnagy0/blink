import CoreGraphics

/// Whether a window covers a display. A full-screen window spans it edge to edge and down over
/// the Dock, starting either at the top or just below a menu bar that stayed visible; a merely
/// zoomed window stops short of the Dock. Rects are in Quartz coordinates.
public enum FullscreenGeometry {
    private static let tolerance: CGFloat = 1

    public static func covers(display: CGRect, menuBar: CGFloat, window: CGRect) -> Bool {
        abs(window.minX - display.minX) <= tolerance
            && abs(window.width - display.width) <= tolerance
            && abs(window.maxY - display.maxY) <= tolerance
            && window.minY >= display.minY - tolerance
            && window.minY <= display.minY + menuBar + tolerance
    }
}
