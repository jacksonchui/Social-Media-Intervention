//
//  MotionManager.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/7/21.
//

import CoreMotion

public struct MotionAttitude: Equatable {
    var roll: Double
    var pitch: Double
    var yaw: Double
}

public enum MotionResult {
    case success(MotionAttitude)
    case failure(MotionSessionError)
}

public enum MotionAvailabilityError: String, Swift.Error {
    case deviceMotionUnavailable = "Device Motion is unavailable"
    case attitudeReferenceFrameUnavailable = "Could not get the desired motion frame for device"
}

public enum MotionSessionError: Swift.Error {
    case anyError
}

public protocol MotionManager {
    
    typealias DeviceMotionHandler = (MotionResult) -> Void
    
    typealias AvailabilityCompletion = (MotionAvailabilityError?) -> Void
    typealias StartCompletion = DeviceMotionHandler
    
    func checkAvailability(completion: @escaping (MotionAvailabilityError?) -> Void)
    func startMotionUpdates(updatingEvery interval: TimeInterval, completion: @escaping DeviceMotionHandler)
}
