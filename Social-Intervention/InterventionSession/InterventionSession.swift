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
    public typealias StartError = ConditionPeriodError
    
    public enum StartResult: Equatable {
        case success(alpha: CGFloat)
        case failure(error: StartError)
    }
    
    private(set) var service: ConditionService
    private(set) var periodTimes = [TimeInterval]()
    private(set) var periodCount: Double //
    
    public typealias CheckCompletion = (CheckError?) -> Void
    public typealias StartCompletion = (StartResult) -> Void
    
    public init (for service: ConditionService) { //
        self.service = service
        self.periodCount = 1
    }
    
    public func check(completion: @escaping CheckCompletion) {
        service.check(completion: completion)
    }
    
    public func start(completion: @escaping StartCompletion) {
        service.start { [weak self] result in
            guard let self = self else { return }
            switch result {
                case let .success(latestMotionProgress: progress):
                    completion(.success(alpha: InterventionPolicy.toAlpha(progress)))
                case let .failure(error):
                    completion(.failure(error: error))
            }
            if self.service.currentPeriodTime >= InterventionPolicy.periodDuration * self.periodCount {
                self.decideNextPeriod()
            }
        }
    }
    
    public func stop() {
        self.service.stop(completion: {_ in })
        // save to analytics
    }
    
    private func decideNextPeriod() {
        if service.progressAboveThreshold >= InterventionPolicy.periodCompletedRatio {
            self.periodTimes.append(self.service.currentPeriodTime)
            self.service.reset()
            self.periodCount = 1
        } else {
            print("Keep running the service with no reset into the next period.")
            self.periodCount += 1
        }
    }
}
