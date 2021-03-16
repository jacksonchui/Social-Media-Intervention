//
//  AttitudeConditionService.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/7/21.
//

import Foundation

public class AttitudeConditionService: ConditionService {
    private(set) var targetAttitude: Attitude?
    private(set) var timeInterval: TimeInterval
    private(set) var records = [Attitude]()
    
    private(set) var attitudeClient: AttitudeMotionClient
        
    public init(with attitudeClient: AttitudeMotionClient, updateEvery timeInterval: TimeInterval) {
        self.attitudeClient = attitudeClient
        self.timeInterval = timeInterval
    }
    
    public var currentPeriodTime: TimeInterval {
        return timeInterval * Double(records.count)
    }
    
    private func resetRecords() { records = [] }
    private func removeTargetAttitudeToAcquireNewOneOnNextUpdate() { targetAttitude = nil }
}

public extension AttitudeConditionService {
    func check(completion: @escaping CheckCompletion) {
        attitudeClient.checkAvailability(completion: completion)
    }
}

public extension AttitudeConditionService {
    func start(completion: @escaping StartCompletion) {
        attitudeClient.startUpdates(updatingEvery: timeInterval) { [weak self] result in
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
        attitudeClient.stopUpdates {[weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(periodCompletedRatio: self.periodCompletedRatio))
        }
    }
    
    public var periodCompletedRatio: Double {
        guard let targetAttitude = targetAttitude else { return 0.0 }
        let progresses = records.toProgresses(target: targetAttitude)
        print("Records above threshold (\(SessionPolicy.successfulProgressThreshold)): \(progresses.recordsAboveThreshold) of \(progresses.count)")
        print("Average progress: \(progresses.average)")
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
        resetRecords()
    }
}

internal extension Double {
    func truncate(places : Int)-> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}

internal extension Attitude {
    func progress(towards target: Attitude) -> Double {
        let maxDiff = Double.pi
        let pitchRatio = abs(self.pitch-target.pitch)/maxDiff
        let yawRatio = abs(self.yaw-target.yaw)/maxDiff
        let rollRatio = abs(self.roll-target.roll)/maxDiff
        print("Yaw, Pitch, Roll Ratios: \(yawRatio), \(rollRatio), \(pitchRatio)")
        
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
            sum + (progress >= SessionPolicy.successfulProgressThreshold ? 1 : 0)
        }
    }
}
