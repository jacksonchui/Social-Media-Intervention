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

public enum PeriodStartResult {
    case success(progress: Double)
    case failure(MotionSessionError)
}

public enum PeriodStopResult {
    case success(progressAboveThreshold: Double)
    case failure(MotionSessionError)
}

public protocol ConditionService: AnyObject {
    
    associatedtype Error
    associatedtype ConditionDelegate
    typealias StartCompletion = (PeriodStartResult) -> Void
    typealias StopCompletion = (PeriodStopResult) -> Void
        
    func start(completion: @escaping (Error?) -> Void) -> Void
    func stop() -> Void
}
