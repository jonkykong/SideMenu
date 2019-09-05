//
//  Print.swift
//  SideMenu
//
//  Created by Jon Kent on 12/5/18.
//

import Foundation

internal enum Print: String { case
    cannotPush = "Attempt to push a View Controller from %@ where its navigationController == nil. It must be embedded in a UINavigationController for this to work.",
    emptyMenu = "The menu doesn't have a view controller to show! SideMenuNavigationController needs a view controller to display just like a UINavigationController.",
    menuAlreadyAssigned = "%@ was already assigned to the %@ of %@. When using multiple SideMenuManagers you may want to use new instances of SideMenuNavigationController instead of existing instances to avoid crashes if the menu is presented more than once.",
    menuInUse = "%@ cannot be modified while it's presented.",
    panGestureAdded = "%@ was called before %@ or %@ was set. Gestures will not work without a menu.",
    property = "A menu's %@ property can only be changed when it is hidden.",
    screenGestureAdded = "%@ was called before %@ was set. The gesture will not work without a menu. Use %@ to add gestures for only one menu.",
    transitioningDelegate = "SideMenu requires use of the transitioningDelegate. It cannot be modified."

    enum PropertyName: String { case
        leftSide
    }

    static func warning(_ print: Print, arguments: CVarArg..., required: Bool = false) {
        warning(String(format: print.rawValue, arguments: arguments), required: required)
    }

    static func warning(_ print: Print, arguments: PropertyName..., required: Bool = false) {
        warning(String(format: print.rawValue, arguments: arguments.map { $0.rawValue }), required: required)
    }

    static func warning(_ print: Print, required: Bool = false) {
        warning(print.rawValue, required: required)
    }
}

private extension Print {

    static func warning(_ message: String, required: Bool = false) {
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
