//
//  InterventionSession.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/10/21.
//

import Foundation

public struct SessionLogEntry: Equatable {
    var progressOverPeriod: [Double]
    var periodDuration: TimeInterval
}

public typealias SessionCheckError = MotionAvailabilityError
public typealias SessionStartError = ConditionPeriodError
public typealias SessionStopError = ConditionPeriodError?


public enum SessionStartResult: Equatable {
    case success(alpha: CGFloat)
    case failure(error: SessionStartError)
}

public protocol SessionManager {
    typealias StopCompletion = (SessionStopError?) -> Void
    typealias CheckCompletion = (SessionCheckError?) -> Void
    typealias StartCompletion = (SessionStartResult) -> Void
    
    func check(completion: @escaping CheckCompletion)
    func start(completion: @escaping StartCompletion)
    func stop(completion: @escaping StopCompletion)
}
