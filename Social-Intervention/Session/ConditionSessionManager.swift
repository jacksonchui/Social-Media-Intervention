//
//  ConditionSessionManager.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/15/21.
//

import Foundation

public final class ConditionSessionManager: SessionManager {
    
    private(set) var service: ConditionService
    private(set) var sessionLog: SessionLog
    private(set) var progressPerInterval = [TimeInterval]()
    private(set) var periodIntervals: Int
    private(set) var currProgressLevel: Double
    
    private var nextPeriodDurationCheckpt: TimeInterval { SessionPolicy.periodDuration * Double(self.periodIntervals) }
    
    public init(using service: ConditionService) {
        self.service = service
        self.periodIntervals = 1
        self.currProgressLevel = 0
        self.sessionLog = SessionLog(startTime: Date(), endTime: Date(), periodLogs: [], socialMediums: [])
    }
    
    public func check(completion: @escaping CheckCompletion) {
        service.check(completion: completion)
    }
    
    public func start(completion: @escaping StartCompletion) {
        sessionLog = setUpSessionLog()
        
        service.start { [unowned self] result in
            switch result {
                case let .success(progressUpdate):
                    let newAlphaLevel = ConditionSessionPolicy.toAlphaLevel(progressUpdate, from: currProgressLevel)
                    currProgressLevel = progressUpdate
                    completion(.success(alpha: newAlphaLevel))
                    print("[LOG] Current Period Progress in Session: \(progressUpdate * 100)%")
                default:
                    break
            }
            
            if self.service.currPeriodDuration >= nextPeriodDurationCheckpt {
                self.onPeriodDurationCheckpoint()
            }
        }
    }
    
    public func stop(completion: @escaping StopCompletion) {
        service.stop { [weak self] result in
            guard let self = self else { return }
            
            switch result {
                case let .stopped(lastRatio):
                    self.onStop(record: lastRatio)
                    self.resetServiceAndManager()
                    completion(.success(log: self.sessionLog))
                case .alreadyStopped:
                    completion(.alreadyStopped)
            }
        }
    }
    
    private func setUpSessionLog() -> SessionLog {
        return SessionLog(startTime: Date(), endTime: Date(), periodLogs: [], socialMediums: [])
    }
    
    private func onPeriodDurationCheckpoint() {
        recordPeriodCompletedRatio()
        recordCompletedRatioAndResetIfCompletedPeriod()
    }
    
    private func onStop(record ratio: Double) {
        sessionLog.endTime = Date()
        progressPerInterval.append(ratio)
        let newPeriodLog = PeriodLog(
                        progressPerInterval: progressPerInterval,
                        duration: service.currPeriodDuration)
        sessionLog.periodLogs.append(newPeriodLog)
    }
    
    private func resetServiceAndManager() {
        service.reset()
        resetPeriod()
    }
    
    private func recordCompletedRatioAndResetIfCompletedPeriod() {
        let latestProgress = progressPerInterval.last ?? 0
        if latestProgress >= SessionPolicy.periodCompletedRatio {
            let newPeriodLog = PeriodLog(
                            progressPerInterval: progressPerInterval,
                            duration: service.currPeriodDuration)
            sessionLog.periodLogs.append(newPeriodLog)
            resetServiceAndManager()
        } else {
            periodIntervals += 1
            service.continuePeriod()
        }
    }
    
    private func recordPeriodCompletedRatio() {
        progressPerInterval.append(service.periodCompletedRatio)
    }
    
    private func resetPeriod() {
        periodIntervals = 1
        progressPerInterval = []
    }
}
