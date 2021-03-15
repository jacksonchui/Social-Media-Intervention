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

public enum ConditionPeriodError: Swift.Error {
    case startError
    case alreadyStopped
}

public enum PeriodStartResult {
    case success(progressUpdate: Double)
    case failure(ConditionPeriodError)
}

public enum PeriodStopResult {
    case success(periodCompletedRatio: Double)
    case failure(ConditionPeriodError)
}

public protocol ConditionService: AnyObject {
    typealias CheckCompletion = (MotionAvailabilityError?) -> Void
    typealias StartCompletion = (PeriodStartResult) -> Void
    typealias StopCompletion = (PeriodStopResult) -> Void
    
    var currentPeriodTime: TimeInterval { get }
    var periodCompletedRatio: Double { get }
    
    func check(completion: @escaping CheckCompletion) -> Void
    func start(completion: @escaping StartCompletion) -> Void
    func stop(completion: @escaping StopCompletion) -> Void
    func reset() -> Void
    func continuePeriod() -> Void
}
