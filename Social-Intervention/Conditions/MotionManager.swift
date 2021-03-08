//
//  MotionManager.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/7/21.
//

import CoreMotion

public struct MotionAttitude {
    var roll: Double
    var pitch: Double
    var yaw: Double
}

public enum MotionAvailabilityError: String, Swift.Error {
    case deviceMotionUnavailable = "Device Motion is unavailable"
    case attitudeReferenceFrameUnavailable = "Could not get the desired motion frame for device"
}

public protocol MotionManager {
    
    typealias DeviceMotionHandler = (MotionAttitude?, Error?) -> Void
    
    typealias AvailabilityCompletion = (MotionAvailabilityError?) -> Void
    typealias StartCompletion = DeviceMotionHandler
    
    func checkAvailability(completion: @escaping (MotionAvailabilityError?) -> Void)
    func startMotionUpdates(completion: @escaping DeviceMotionHandler)
}
