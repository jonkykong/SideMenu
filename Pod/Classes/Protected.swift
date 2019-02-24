//
//  Protected.swift
//  SideMenu
//
//  Created by Jon Kent on 2/9/19.
//

import Foundation

open class Protected<T: Equatable> {

    typealias ConditionBlock = () -> Bool
    typealias Block = (Protected) -> Void

    private var _value: T
    private var conditionBlock: ConditionBlock
    private var thenBlock: Block?
    private var elseBlock: Block?

    open var value: T {
        get {
            return _value
        }
        set {
            guard conditionBlock() else {
                elseBlock?(self)
                //Print.warning(.property, arguments: warning, required: true)
                return
            }
            _value = newValue
            thenBlock?(self)
        }
    }

//    func set(_ newValue: T, if condition: ConditionBlock) {
//        guard condition else {
//            //Print.warning(.property, arguments: warning, required: true)
//            return
//        }
//        _value = newValue
//    }

    init(_ value: T, if conditionBlock: @escaping ConditionBlock, then thenBlock: Block? = nil, else elseBlock: Block? = nil) {
        self._value = value
        self.conditionBlock = conditionBlock
        self.thenBlock = thenBlock
        self.elseBlock = elseBlock
    }
}
