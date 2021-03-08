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
    
    init(with motionManager: MotionManager, saveTo store: ConditionStore, updateEvery timeInterval: TimeInterval) {
        self.motionManager = motionManager
        self.timeInterval = timeInterval
        self.conditionStore = store
    }
    
    public func check(completion: @escaping (MotionAvailabilityError?) -> Void) {
        motionManager.checkAvailability(completion: completion)
    }
    
    public func start(completion: @escaping ConditionService.SessionErrorCompletion) {
        currentPeriodTime = 0
        motionManager.startUpdates(updatingEvery: timeInterval) { [weak self] result in
            guard let self = self else { return }
            self.record(result: result, completion: completion)
        }
    }
    
    public func stop(completion: @escaping ConditionService.SessionErrorCompletion) {
        motionManager.stopUpdates {[weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                completion(error)
                return
            }
            self.resetConditionServiceState()
            completion(nil)
        }
    }
    
    private func record(result: MotionResult, completion: @escaping ConditionService.SessionErrorCompletion) {
        switch result {
            case let .success(attitude):
                if initialAttitude == nil {
                    initialAttitude = attitude
                    targetAttitude = randomAttitude
                }
                currentPeriodTime += timeInterval
                conditionStore.record(attitude)
                completion(nil)
            case let .failure(error):
                completion(error)
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
}

private extension Double {
    func truncate(places : Int)-> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}
