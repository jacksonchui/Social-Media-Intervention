//
//  ConditionService.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/7/21.
//

import Foundation

public enum PeriodStartResult {
    case success(progressUpdate: Double)
    case failure(Error)
    case alreadyStarted
}

public enum PeriodStopResult {
    case stopped
    case alreadyStopped
}

public protocol ConditionService: AnyObject {
    typealias CheckCompletion = (MotionAvailabilityError?) -> Void
    typealias StartCompletion = (PeriodStartResult) -> Void
    typealias StopCompletion = (PeriodStopResult) -> Void
    
    var currPeriodDuration: TimeInterval { get }
    var periodCompletedRatio: Double { get }
    
    func check(completion: @escaping CheckCompletion) -> Void
    func start(completion: @escaping StartCompletion) -> Void
    func stop(completion: @escaping StopCompletion) -> Void
    func reset() -> Void
    func continuePeriod() -> Void
}
