//
//  Print.swift
//  SideMenu
//
//  Created by Jon Kent on 12/5/18.
//

import Foundation

public enum Print: String { case
    panGestureAdded = "%@ was called before %@ or %@ was set. Gestures will not work without a menu.",
    screenGestureAdded = "%@ was called before %@ was set. The gesture will not work without a menu. Use %@ to add gestures for only one menu.",
    menuAlreadyAssigned = "%@ was already assigned to the %@ of %@. When using multiple SideMenuManagers you may want to use new instances of UISideMenuNavigationController instead of existing instances to avoid crashes if the menu is presented more than once.",
    menuInUse = "%@ cannot be modified while it's presented.",
    property = "a menu's %@ property can only be changed when it is hidden.",
    emptyMenu = "SideMenu Warning: the menu doesn't have a view controller to show! UISideMenuNavigationController needs a view controller to display just like a UINavigationController.",
    cannotPush = "SideMenu Warning: attempt to push a View Controller from %@ where its navigationController == nil. It must be embedded in a UINavigationController for this to work."

    internal static func warning(_ print: Print, arguments: CVarArg..., required: Bool = false) {
        warning(String(format: print.rawValue, arguments), required: required)
    }

    internal static func warning(_ print: Print, required: Bool = false) {
        warning(print.rawValue, required: required)
    }
}

private extension Print {

    private static func warning(_ message: String, required: Bool = false) {
        let message = "SideMenu Warning: \(message)"

        if required {
            print(message)
            return
        }
        #if !STFU_SIDEMENU
        print(message)
        #endif
    }

}
