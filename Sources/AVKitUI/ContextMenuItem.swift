//
//  ContextMenuItem.swift
//  AVKitUI
//
//  Created by Bradley Lindauer on 5/23/26.
//

#if os(macOS)

import AppKit

public protocol PlayerContextMenuControlling {
    func closeMenu()
}

public enum ContextMenuItem {
    public typealias Action = () -> Void
    public typealias IsEnabled = () -> Bool
    public typealias ViewProvider = (PlayerContextMenuControlling?) -> NSView

    case separator
    case action(title: String, isEnabled: IsEnabled?, action: Action)
    case customView(viewProvider: ViewProvider)

    public static func item(
        title: String,
        isEnabled: IsEnabled? = nil,
        action: @escaping Action
    ) -> Self {
        .action(title: title, isEnabled: isEnabled, action: action)
    }

}

struct MenuController: PlayerContextMenuControlling {
    let menu: NSMenu

    func closeMenu() {
        menu.cancelTracking()
    }
}

#endif