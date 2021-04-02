//
//  InterventionSession.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/10/21.
//

import Foundation

public struct PeriodLog: Equatable, Codable {
    var progressPerInterval: [Double]
    var duration: TimeInterval
}

public struct SessionLog: Equatable, Codable {
    var startTime: Date
    var endTime: Date?
    var periodLogs: [PeriodLog]
}

public typealias SessionCheckError = MotionAvailabilityError

public enum SessionStartResult {
    case success(alpha: Double)
    case failure(error: Error?)
}

public protocol SessionManager {
    typealias StopCompletion = () -> Void
    typealias CheckCompletion = (SessionCheckError?) -> Void
    typealias StartCompletion = (SessionStartResult) -> Void
    
    func check(completion: @escaping CheckCompletion)
    func start(loggingTo: SessionLog?, completion: @escaping StartCompletion)
    func stop(completion: @escaping StopCompletion)
}
