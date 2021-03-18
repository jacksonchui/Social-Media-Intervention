//
//  ConditionSessionManager.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/15/21.
//

import Foundation
import CoreGraphics

public final class ConditionSessionManager: SessionManager {
    
    private(set) var service: ConditionService
    private(set) var sessionLog: SessionLog?
    private(set) var progressPerInterval = [Double]()
    private(set) var periodIntervals: Int
    
    private var nextPeriodDurationCheckpt: Double { SessionPolicy.periodDuration * Double(self.periodIntervals) }
    
    public init(using service: ConditionService) {
        self.service = service
        self.periodIntervals = 1
    }
    
    public func check(completion: @escaping CheckCompletion) {
        service.check(completion: completion)
    }
    
    public func start(loggingTo sessionLog: SessionLog?, completion: @escaping StartCompletion) {
        self.sessionLog = sessionLog ?? setUpSessionLog()
        
        service.start { [unowned self] result in
            switch result {
                case let .success(progressUpdate):
                    let alphaLevel = ConditionSessionPolicy.toAlphaLevel(progressUpdate)
                    completion(.success(alpha: alphaLevel))
                default:
                    break
            }
            
            if self.service.currPeriodDuration >= nextPeriodDurationCheckpt {
                self.onPeriodIntervalCheckpoint()
            }
        }
    }
    
    public func stop(completion: @escaping StopCompletion) {
        service.stop { result in
            switch result {
                case .stopped:
                    self.onSuccessfulStopRecordLatestPeriodProgress()
                case .alreadyStopped:
                    break
            }
            completion()
        }
    }
    
    private func setUpSessionLog() -> SessionLog {
        return SessionLog(startTime: Date(), endTime: nil, periodLogs: [])
    }
    
    private func onPeriodIntervalCheckpoint() {
        recordPeriodCompletedRatio()
        completeThePeriodAndResetIfProgressIsCompleted()
    }
    
    private func onSuccessfulStopRecordLatestPeriodProgress() {
        recordPeriodCompletedRatio()
        let newPeriodLog = PeriodLog(
                        progressPerInterval: progressPerInterval,
                        duration: service.currPeriodDuration)
        sessionLog?.periodLogs.append(newPeriodLog)
        service.reset()
        resetPeriod()
    }
    
    private func completeThePeriodAndResetIfProgressIsCompleted() {
        let latestProgress = progressPerInterval.last ?? 0
        if latestProgress >= SessionPolicy.periodCompletedRatio {
            let newPeriodLog = PeriodLog(
                            progressPerInterval: progressPerInterval,
                            duration: service.currPeriodDuration)
            sessionLog?.periodLogs.append(newPeriodLog)
            service.reset()
            resetPeriod()
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
