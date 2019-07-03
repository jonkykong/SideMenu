//
//  Protected.swift
//  SideMenu
//
//  Created by Jon Kent on 2/9/19.
//

import Foundation

internal final class Protected<T: Equatable> {

    typealias ConditionBlock = (T) -> Bool
    typealias Block = (T) -> Void

    private var _value: T
    private var conditionBlock: ConditionBlock
    private var thenBlock: Block?
    private var elseBlock: Block?

    public var value: T {
        get {
            return _value
        }
        set {
            guard conditionBlock(_value) else {
                elseBlock?(_value)
                return
            }
            _value = newValue
            thenBlock?(_value)
        }
    }

    init(_ value: T, if conditionBlock: @escaping ConditionBlock, then thenBlock: Block? = nil, else elseBlock: Block? = nil) {
        self._value = value
        self.conditionBlock = conditionBlock
        self.thenBlock = thenBlock
        self.elseBlock = elseBlock
    }
}
