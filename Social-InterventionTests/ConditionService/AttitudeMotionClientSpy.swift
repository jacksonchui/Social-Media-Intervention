//
//  AttitudeMotionClientSpy.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/10/21.
//

import Foundation

class AttitudeMotionClientSpy: AttitudeMotionClient {
    
    init(updateInterval: TimeInterval) { }
            
    var availabilityCompletions = [AvailabilityCompletion]()
    var startCompletions = [StartCompletion]()
    var stopCompletions = [StopCompletion]()
    
    var initialAttitude: Attitude?
    
    func checkAvailability(completion: @escaping (MotionAvailabilityError?) -> Void) {
        availabilityCompletions.append(completion)
    }
    
    func startUpdates(updatingEvery interval: TimeInterval, completion: @escaping StartCompletion) {
        initialAttitude = Attitude(roll: 0, pitch: 0, yaw: 0)
        startCompletions.append(completion)
    }
    
    func stopUpdates(completion: @escaping StopCompletion) {
        stopCompletions.append(completion)
    }
    
    func complete(with error: MotionAvailabilityError, at index: Int = 0) {
        availabilityCompletions[index](error)
    }
    
    func completeWithNoCheckErrors(at index: Int = 0) {
        availabilityCompletions[index](nil)
    }
    
    func completeStartUpdatesSuccessfully(with attitude: Attitude, at index: Int = 0) {
        startCompletions[index](.success(attitude))
    }
    
    func completeStartUpdates(with error: ConditionPeriodError, at index: Int = 0) {
        startCompletions[index](.failure(error))
    }
    
    func completeStopUpdates(with error: ConditionPeriodError?, at index: Int = 0) {
        stopCompletions[index](error)
    }
    
    func completeStopUpdatesSuccessfully(at index: Int = 0) {
        stopCompletions[index](nil)
    }
}
