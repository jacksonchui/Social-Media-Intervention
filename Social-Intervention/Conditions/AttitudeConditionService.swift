//
//  AttitudeConditionService.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/7/21.
//

import Foundation

public class AttitudeConditionService {
    
    private(set) var motionManager: MotionManager
    private(set) var conditionStore: ConditionStore
    
    private(set) var currentPeriodTime: TimeInterval = 0
    private(set) var initialAttitude: Attitude?
    private(set) var targetAttitude: Attitude?
    private var timeInterval: TimeInterval
    
    static let resetProgressLevel = 1.0
    
    init(with motionManager: MotionManager, saveTo store: ConditionStore, updateEvery timeInterval: TimeInterval) {
        self.motionManager = motionManager
        self.timeInterval = timeInterval
        self.conditionStore = store
    }
    
    public func check(completion: @escaping (MotionAvailabilityError?) -> Void) {
        motionManager.checkAvailability(completion: completion)
    }
    
    public func start(completion: @escaping ConditionService.PeriodCompletion) {
        currentPeriodTime = 0
        motionManager.startUpdates(updatingEvery: timeInterval) { [weak self] result in
            guard let self = self else { return }
            self.record(result: result, completion: completion)
        }
    }
    
    public func stop(completion: @escaping ConditionService.PeriodCompletion) {
        motionManager.stopUpdates {[weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            self.resetConditionServiceState()
            completion(.success(progress: AttitudeConditionService.resetProgressLevel))
        }
    }
    
    private func record(result: MotionResult, completion: ConditionService.PeriodCompletion) {
        switch result {
            case let .success(attitude):
                if initialAttitude == nil {
                    initialAttitude = attitude
                    targetAttitude = randomAttitude
                }
                currentPeriodTime += timeInterval
                conditionStore.record(attitude)
                completion(.success(progress: progress))
            case let .failure(error):
                completion(.failure(error))
        }
    }
    
    private func resetConditionServiceState() {
        currentPeriodTime = 0
        initialAttitude = nil
        targetAttitude = nil
    }
    
    private var randomRadian: Double {
        let sigFigures = 2
        return Double.random(in: -Double.pi/2...Double.pi/2).truncate(places: sigFigures)
    }
    
    private var randomAttitude: Attitude {
        let newAttitude = Attitude(roll: randomRadian, pitch: randomRadian, yaw: randomRadian)
        return newAttitude != initialAttitude ? newAttitude : self.randomAttitude
    }
    
    private var progress: Double { conditionStore.progress(to: targetAttitude) }
}

internal extension Double {
    func truncate(places : Int)-> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}