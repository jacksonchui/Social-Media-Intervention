//
//  CMAttitudeMotionService.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/10/21.
//

import CoreMotion

class CMAttitudeMotionClient: AttitudeMotionClient {
    let motionManager: CMMotionManager
    let queue: OperationQueue
    let referenceFrame: CMAttitudeReferenceFrame = .xArbitraryZVertical
    
    init(updateInterval: TimeInterval) {
        motionManager = CMMotionManager(with: updateInterval)
        queue = OperationQueue("CMAttitudeMotion", ofType: .serial)
    }
    
    func checkAvailability(completion: @escaping AvailabilityCompletion) {
        guard motionManager.isDeviceMotionAvailable else {
            completion(.deviceMotionUnavailable)
            return
        }
        
        guard CMMotionManager.availableAttitudeReferenceFrames().contains(referenceFrame) else {
            completion(.attitudeReferenceFrameUnavailable)
            return
        }
    }
    
    func startUpdates(updatingEvery interval: TimeInterval, completion: @escaping StartCompletion) {
        if motionManager.isDeviceMotionActive {
            completion(.alreadyStarted)
        }
        
        motionManager.startDeviceMotionUpdates(using: referenceFrame, to: queue) { deviceMotion, error in
            guard let deviceMotion = deviceMotion, error == nil else {
                completion(.failure(error!))
                return
            }
            completion(.success(deviceMotion.attitude.toModel()))
        }
    }
    
    func stopUpdates(completion: @escaping StopCompletion) {
        guard motionManager.isDeviceMotionActive else {
            completion()
            return
        }
        motionManager.stopDeviceMotionUpdates()
        completion()
    }
}

extension CMAttitude {
    func toModel() -> Attitude {
        Attitude(roll: self.roll, pitch: self.pitch, yaw: self.yaw)
    }
}

internal extension CMMotionManager {
    convenience init(with updateInterval: TimeInterval) {
        self.init()
        self.deviceMotionUpdateInterval = updateInterval
    }
}

internal extension OperationQueue {
    enum ConcurrentOperations: Int {
        case serial = 1
    }
    
    convenience init(_ name: String, ofType: ConcurrentOperations) {
        self.init()
        self.name = name
        self.maxConcurrentOperationCount = ofType.rawValue
    }
}
