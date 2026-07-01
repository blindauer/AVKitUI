//
//  PlayerPointerActivity.swift
//  AVKitUI
//
//  Created by Bradley Lindauer on 5/23/26.
//

#if os(macOS)

import AppKit
import CoreGraphics

public enum PlayerPointerPhase: Sendable {
    case moved
    case entered
    case exited
    case modifiersChanged
    case clicked
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

#endif
