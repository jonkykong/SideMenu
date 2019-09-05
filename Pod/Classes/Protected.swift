//
//  Protected.swift
//  SideMenu
//
//  Created by Jon Kent on 2/9/19.
//

import Foundation

internal final class Protected<T: Equatable> {

    typealias ConditionBlock = (_ oldValue: T, T) -> T

    private var _value: T
    private var condition: ConditionBlock

    public var value: T {
        get { return _value }
        set { _value = condition(_value, newValue) }
    }

    init(_ value: T, when condition: @escaping ConditionBlock) {
        self._value = value
        self.condition = condition
    }
}
