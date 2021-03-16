//
//  ConditionSessionManager.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/15/21.
//

import Foundation
import CoreGraphics

public final class ConditionSessionManager: SessionManager {
        
    public enum StartResult: Equatable {
        case success(alpha: CGFloat)
        case failure(error: ConditionPeriodError)
    }
    
    private(set) var service: ConditionService
    private(set) var analytics: SIAnalyticsController
    private(set) var sessionLog = [SessionLogEntry]()
    private(set) var progressOverPeriod = [Double]()
    private(set) var periodCount: Int
    
    public init(using service: ConditionService, sendsLogTo analytics: SIAnalyticsController) {
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
                case let .success(progressUpdate: progress):
                    let alphaLevel = ConditionSessionPolicy.toAlphaLevel(progress)
                    completion(.success(alpha: alphaLevel))
                default:
                    break
            }
            
            if self.service.currentPeriodTime >= SessionPolicy.periodDuration * Double(self.periodCount) {
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
        progressOverPeriod.append(service.periodCompletedRatio)
        
        if progressOverPeriod.last! >= SessionPolicy.periodCompletedRatio {
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
