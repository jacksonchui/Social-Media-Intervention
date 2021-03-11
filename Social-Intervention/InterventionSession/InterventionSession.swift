//
//  InterventionSession.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/10/21.
//

import Foundation
import CoreGraphics

public final class InterventionSession {
    
    public typealias CheckError = MotionAvailabilityError
    public enum StartResult: Equatable {
        case success(alpha: CGFloat)
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
                    let alpha = InterventionPolicy.convertToAlpha(progress)
                    completion(.success(alpha: alpha))
                case let .failure(error):
                    completion(.failure(error: error))
            }
        }
    }
    
}