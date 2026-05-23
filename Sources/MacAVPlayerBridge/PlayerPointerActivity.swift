import AppKit
import CoreGraphics

public enum PlayerPointerPhase: Sendable {
    case moved
    case entered
    case modifiersChanged
}

public struct PlayerPointerActivity: Sendable {
    public let location: CGPoint
    public let modifiers: NSEvent.ModifierFlags
    public let phase: PlayerPointerPhase

    public init(location: CGPoint, modifiers: NSEvent.ModifierFlags, phase: PlayerPointerPhase) {
        self.location = location
        self.modifiers = modifiers
        self.phase = phase
    }
}
