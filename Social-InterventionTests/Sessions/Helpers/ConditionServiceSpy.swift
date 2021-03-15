//
//  ConditionServiceSpy.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/15/21.
//

import Foundation

class ConditionServiceSpy: ConditionService {
    var currentPeriodTime: TimeInterval
    var periodCompletedRatio: Double
    
    var checkCompletions = [CheckCompletion]()
    var startCompletions = [StartCompletion]()
    var stopCompletions = [StopCompletion]()
    
    init() {
        currentPeriodTime = 0
        periodCompletedRatio = 0
    }
    
    func check(completion: @escaping CheckCompletion) {
        checkCompletions.append(completion)
    }
    
    func start(completion: @escaping StartCompletion) {
        startCompletions.append(completion)
    }
    
    func stop(completion: @escaping StopCompletion) {
        stopCompletions.append(completion)
    }
    
    func reset() {
        currentPeriodTime = 0
        periodCompletedRatio = 0
    }
    
    func continuePeriod() {
        periodCompletedRatio = 0
    }
    
    func completeCheck(with error: SessionCheckError?, at index: Int = 0) {
        checkCompletions[index](error)
    }
    
    func completeStartSuccessfully(with progress: Double, at index: Int = 0) {
        currentPeriodTime += 1
        startCompletions[index](.success(progressUpdate: progress))
    }
    
    func completeStopSuccessfully(at index: Int = 0) {
        stopCompletions[index](.success(periodCompletedRatio: anyProgress()))
    }
}
