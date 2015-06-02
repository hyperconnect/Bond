//
//  Bond+Ext.swift
//  azar
//
//  Created by dgoon on 2015. 2. 25..
//  Copyright (c) 2015년 HyperConnect. All rights reserved.
//

import Foundation

infix operator <- { associativity left precedence 100 }

public func <- <T>(left: Dynamic<T>, right: T) {
    left.value = right
}

public func <- <T: Dynamical, U where T.DynamicType == U>(left: T, right: U) {
    left.designatedDynamic.value = right
}
