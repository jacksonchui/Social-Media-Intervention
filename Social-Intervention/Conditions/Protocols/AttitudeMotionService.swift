//
//  AttitudeMotionService.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/7/21.
//

import CoreMotion

public struct Attitude: Equatable {
    var roll: Double
    var pitch: Double
    var yaw: Double
}

public enum AttitudeResult {
    case success(Attitude)
    case failure(ConditionPeriodError)
}

public enum MotionAvailabilityError: String, Swift.Error {
    case deviceMotionUnavailable = "Device Motion is unavailable"
    case attitudeReferenceFrameUnavailable = "Could not get the desired motion frame for device"
}

public protocol AttitudeMotionService {
    typealias AvailabilityCompletion = (MotionAvailabilityError?) -> Void
    typealias StartCompletion = (AttitudeResult) -> Void
    typealias StopCompletion = (ConditionPeriodError?) -> Void
    
    func checkAvailability(completion: @escaping AvailabilityCompletion)
    func startUpdates(updatingEvery interval: TimeInterval, completion: @escaping StartCompletion)
    func stopUpdates(completion: @escaping StopCompletion)
}
