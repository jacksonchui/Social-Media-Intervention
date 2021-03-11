//
//  AttitudeConditionService.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/7/21.
//

import Foundation

public class AttitudeConditionService: ConditionService {
    private(set) var attitudeClient: AttitudeMotionClient
    
    private(set) var targetAttitude: Attitude?
    private(set) var timeInterval: TimeInterval
    private(set) var records = [Attitude]()
    
    static let progressThreshold = 0.7
    
    init(with attitudeClient: AttitudeMotionClient, updateEvery timeInterval: TimeInterval) {
        self.attitudeClient = attitudeClient
        self.timeInterval = timeInterval
    }
    
    public var currentPeriodTime: TimeInterval {
        return timeInterval * Double(records.count)
    }
}

extension AttitudeConditionService {
    public func check(completion: @escaping CheckCompletion) {
        attitudeClient.checkAvailability(completion: completion)
    }
}

extension AttitudeConditionService {
    public func start(completion: @escaping StartCompletion) {
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
                completion(.success(latestMotionProgress: progress))
            case let .failure(error):
                completion(.failure(error))
        }
    }
    
    private var progress: Double {
        guard let record = records.last,
              let targetAttitude = targetAttitude else {
            return 1.0
        }
        return record.progress(till: targetAttitude)
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
            completion(.success(progressAboveThreshold: self.progressAboveThreshold))
        }
    }
    
    public var progressAboveThreshold: Double {
        guard let targetAttitude = targetAttitude else { return 0.0 }
        let progresses = records.map { $0.progress(till: targetAttitude) }
        let recordsAboveThreshold = progresses.reduce(0) { sum, progress in sum + (progress >= AttitudeConditionService.progressThreshold ? 1 : 0) }
        print("Records above threshold (\(AttitudeConditionService.progressThreshold)): \(recordsAboveThreshold) of \(progresses.count)")
        print("Average progress: \(progresses.reduce(0.0) { $0 + $1 } / Double(progresses.count))")
        return Double(recordsAboveThreshold) / Double(progresses.count)
    }
}

extension AttitudeConditionService {
    public func reset() {
        records = []
        targetAttitude = nil
    }
}

internal extension Double {
    func truncate(places : Int)-> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}

internal extension Attitude {
    func progress(till target: Attitude) -> Double {
        let maxDiff = Double.pi
        let diff = abs(self.pitch-target.pitch) + abs(self.yaw-target.yaw) + abs(self.roll-target.roll)
        let progress = 1.0 - (diff/maxDiff/3.0)
        return progress.truncate(places: 2)
    }
}
