//
//  ViewAlphaInterventionSession.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/15/21.
//

import Foundation
import CoreGraphics

class ViewAlphaInterventionSession {
    
    public typealias CheckError = MotionAvailabilityError
    public typealias CheckCompletion = (CheckError?) -> Void
    
    public enum StartResult: Equatable {
        case success(alpha: CGFloat)
        case failure(error: ConditionPeriodError)
    }
    public typealias StartCompletion = (StartResult) -> Void
    
    public typealias StopError = ConditionPeriodError?
    public typealias StopCompletion = (StopError) -> Void
    
    private(set) var service: ConditionService
    private(set) var analytics: SIAnalyticsController
    private(set) var sessionLog = [SessionLogEntry]()
    private(set) var progressOverPeriod = [Double]()
    private(set) var periodCount: Int
    
    init(using service: ConditionService, sendsLogTo analytics: SIAnalyticsController) {
        self.service = service
        self.analytics = analytics
        self.periodCount = 1
    }
    
    public func check(completion: @escaping CheckCompletion) {
        service.check(completion: completion)
    }
    
    public func start(completion: @escaping StartCompletion) {
        service.start { [unowned self] result in
            switch result {
                case let .success(latestMotionProgress: progress):
                    completion(.success(alpha: InterventionPolicy.toAlpha(progress)))
                default:
                    break
            }
            
            if self.service.currentPeriodTime >= InterventionPolicy.periodDuration * Double(self.periodCount) {
                self.decideNextPeriod()
            }
        }
    }
    
    public func stop(completion: @escaping StopCompletion) {
        service.stop { result in
            switch result {
                case let .failure(error):
                    completion(error)
                default:
                    break
            }
        }
        analytics.save(sessionLog)
    }
    
    private func decideNextPeriod() {
        progressOverPeriod.append(service.progressAboveThreshold)
        
        if progressOverPeriod.last! >= InterventionPolicy.periodCompletedRatio {
            let entry = SessionLogEntry(
                            progressOverPeriod: progressOverPeriod,
                            periodDuration: service.currentPeriodTime)
            sessionLog.append(entry)
            service.reset()
            resetPeriod()
        } else {
            periodCount += 1
            service.continuePeriod()
        }
    }
    
    private func resetPeriod() {
        periodCount = 1
        progressOverPeriod = []
    }
}
