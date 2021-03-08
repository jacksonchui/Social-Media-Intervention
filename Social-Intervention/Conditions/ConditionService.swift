//
//  ConditionService.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/7/21.
//

import Foundation

public protocol ConditionServiceDelegate: AnyObject {
    func condition(progress: Double)
}

public protocol ConditionService: AnyObject {
    
    associatedtype Error
    associatedtype ConditionDelegate
    typealias ProgressHandler = (Progress) -> Void
        
    func start(completion: @escaping (Error?) -> Void) -> Void
    func stop() -> Void
}
