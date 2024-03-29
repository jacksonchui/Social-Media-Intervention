//
//  AttitudeConditionService.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/7/21.
//

import Foundation

public class AttitudeConditionService: ConditionService {
    private(set) var targetAttitude: Attitude?
    private(set) var updateDuration: TimeInterval
    private(set) var records = [Attitude]()
    private(set) var intervals: Double = 0
    
    private(set) var attitudeClient: AttitudeMotionClient
        
    public init(with attitudeClient: AttitudeMotionClient, updateEvery duration: TimeInterval) {
        self.attitudeClient = attitudeClient
        self.updateDuration = duration
    }
    
    public var currPeriodDuration: TimeInterval {
        let currDuration = intervals * SessionPolicy.periodDuration + updateDuration * Double(records.count)
        return currDuration.truncate(places: 2)
    }
    
    private func recordInterval() { intervals += 1 }
    private func resetRecords() { records = [] }
    private func removeTargetAttitudeToAcquireNewOneOnNextUpdate() {
        targetAttitude = nil
        intervals = 0
    }
}

public extension AttitudeConditionService {
    func check(completion: @escaping CheckCompletion) {
        attitudeClient.checkAvailability(completion: completion)
    }
}

public extension AttitudeConditionService {
    func start(completion: @escaping StartCompletion) {
        attitudeClient.startUpdates(updatingEvery: updateDuration) { [weak self] result in
            guard let self = self else { return }
            self.record(result: result, completion: completion)
        }
    }
    
    private func record(result: AttitudeResult, completion: StartCompletion) {
        switch result {
            case let .success(attitude):
                if targetAttitude == nil, records.isEmpty {
                    targetAttitude = randomAttitude
                }
                records.append(attitude)
                completion(.success(progressUpdate: progress))
            case let .failure(error):
                completion(.failure(error))
            case .alreadyStarted:
                completion(.alreadyStarted)
        }
    }
    
    private var progress: Double {
        guard let record = records.last,
              let targetAttitude = targetAttitude else {
            return 1.0
        }
        return record.progress(towards: targetAttitude)
    }
    
    private var randomRadian: Double {
        let sigFigures = 2
        return Double.random(in: -Double.pi/2...Double.pi/2).truncate(places: sigFigures)
    }
    
    private var randomAttitude: Attitude {
        let newAttitude = Attitude(roll: randomRadian, pitch: randomRadian, yaw: randomRadian)
        return newAttitude != records.first ? newAttitude : self.randomAttitude
    }
}

extension AttitudeConditionService {
    public func stop(completion: @escaping StopCompletion) {
        let lastRatio = periodCompletedRatio
        attitudeClient.stopUpdates {
            completion(.stopped(lastRatio: lastRatio))
        }
    }
    
    public var periodCompletedRatio: Double {
        guard let targetAttitude = targetAttitude else { return 0.0 }
        let progresses = records.toProgresses(target: targetAttitude)
        //print("[LOG] Records above threshold (\(SessionPolicy.intervalCompleteThreshold)): \(progresses.recordsAboveThreshold) of \(progresses.count)")
        print("[LOG] progresses.count: \(progresses.count)")
        let periodCompletedRatio = Double(progresses.recordsAboveThreshold) / Double(progresses.count)
        return periodCompletedRatio
    }
}

public extension AttitudeConditionService {
    func reset() {
        resetRecords()
        removeTargetAttitudeToAcquireNewOneOnNextUpdate()
    }
}

public extension AttitudeConditionService {
    func continuePeriod() {
        recordInterval()
        resetRecords()
    }
}

internal extension Attitude {
    func progress(towards target: Attitude) -> Double {
        let maxDiff = Double.pi
        let pitchRatio = abs(self.pitch-target.pitch)/maxDiff
        let yawRatio = abs(self.yaw-target.yaw)/maxDiff
        let rollRatio = abs(self.roll-target.roll)/maxDiff
        
        let progress = 1.0 - [pitchRatio, yawRatio, rollRatio].average
        return progress.truncate(places: 2)
    }
}

internal extension Array where Element == Attitude {
    func toProgresses(target: Attitude) -> [Double] {
        return self.map { $0.progress(towards: target) }
    }
}

internal extension Array where Element == Double {
    var average: Double {
        return self.reduce(0.0) { $0 + $1 } / Double(self.count)
    }
    
    var recordsAboveThreshold: Int {
        return self.reduce(0) { sum, progress in
            sum + (progress >= SessionPolicy.intervalCompleteThreshold ? 1 : 0)
        }
    }
}
