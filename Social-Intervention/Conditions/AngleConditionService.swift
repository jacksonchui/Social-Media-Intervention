//
//  AngleConditionService.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/7/21.
//

import Foundation

public class AngleConditionService {
    
    private(set) var motionManager: MotionManager
    private(set) var conditionStore: ConditionStore
    
    private(set) var currentPeriodTime: TimeInterval = 0
    private(set) var startAttitude: MotionAttitude?
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
        motionManager.startMotionUpdates(updatingEvery: timeInterval) { [weak self] result in
            guard let self = self else { return }
            self.record(result: result, completion: completion)
        }
    }
    
    private func record(result: MotionResult, completion: @escaping ConditionService.SessionErrorCompletion) {
        currentPeriodTime += timeInterval
        switch result {
            case let .success(attitude):
                if startAttitude == nil {
                    startAttitude = attitude
                }
                self.conditionStore.record(attitude)
                completion(nil)
            case let .failure(error):
                completion(error)
        }
    }
    
}
