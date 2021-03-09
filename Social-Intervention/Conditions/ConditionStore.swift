//
//  ConditionStore.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/7/21.
//

import Foundation

public protocol ConditionStore: AnyObject {
    typealias Record = Attitude
    
    func record(_ record: Record) -> Void
    func progress(to target: Record?) -> Double
}
