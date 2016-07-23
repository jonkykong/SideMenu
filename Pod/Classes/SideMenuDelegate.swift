//
//  SideMenuDelegate.swift
//  Pods
//
//  Created by Fernando Jordán Silva on 23/7/16.
//
//

import UIKit

@objc
public protocol  SideMenuDelegate: NSObjectProtocol {
    
    optional func sideMenuWillClose()
    
    optional func sideMenuDidClose()
        
    optional func sideMenuWillOpen()
        
    optional func sideMenuDidOpen()
}
