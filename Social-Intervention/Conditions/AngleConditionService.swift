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
    
    private var timer: Timer?
    private(set) var currentSessionTime: TimeInterval = 0
    private(set) var startAttitude: MotionAttitude?
    private var timeInterval: TimeInterval
    
    init(with motionManager: MotionManager, savingTo store: ConditionStore, every timeInterval: TimeInterval) {
        self.motionManager = motionManager
        self.timeInterval = timeInterval
        self.conditionStore = store
    }
    
    public func check(completion: @escaping (MotionAvailabilityError?) -> Void) {
        motionManager.checkAvailability(completion: completion)
        startTimer()
    }
    
    public func start(completion: @escaping ConditionService.SessionErrorCompletion) {
        startTimer()
        motionManager.startMotionUpdates { [weak self] result in
            guard let self = self else { return }
            self.record(result: result, completion: completion)
        }
    }
    
    private func record(result: MotionResult, completion: @escaping ConditionService.SessionErrorCompletion) {
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
    
    private func startTimer() {
        if timer != nil { stopTimer() }
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: onEachInterval)
    }
    
    private func stopTimer() {
        currentSessionTime = 0
        timer?.invalidate()
        timer = nil
    }
    
    private func onEachInterval(timer: Timer) {
        currentSessionTime += 1
    }
}
