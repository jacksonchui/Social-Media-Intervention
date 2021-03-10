//
//  InterventionSession.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/10/21.
//

import Foundation

public final class InterventionSession {
    
    public typealias CheckError = MotionAvailabilityError
    public enum StartResult: Equatable {
        case success(progress: Double)
        case failure(error: ConditionPeriodError)
    }
    
    private(set) var service: ConditionService
    private(set) var interval: TimeInterval
    
    public typealias CheckCompletion = (CheckError?) -> Void
    public typealias StartCompletion = (StartResult) -> Void
    
    public init (for service: ConditionService, updatingEvery interval: TimeInterval) {
        self.service = service
        self.interval = interval
    }
    
    public func check(completion: @escaping CheckCompletion) {
        service.check(completion: completion)
    }
    
    public func start(completion: @escaping StartCompletion) {
        service.start { result in
            switch result {
                case let .success(latestMotionProgress: progress):
                    completion(.success(progress: progress))
                case let .failure(error):
                    completion(.failure(error: error))
            }
        }
    }
    
}
