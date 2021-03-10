//
//  RotationConditionService.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 2/28/21.
//

import CoreMotion

class RotationConditionService {
    
    enum Error: String, Swift.Error {
        case deviceMotionUnavailable = "Device Motion is unavailable"
        case attitudeReferenceFrameUnavailable = "Could not get the desired motion frame for device"
    }
    
    let motionManager: CMMotionManager
    let queue: OperationQueue
    
    weak var delegate: ConditionServiceDelegate?
    
    static var defaultUpdateInterval: TimeInterval { return 0.1 }
    
    init(withUpdateInterval: TimeInterval = RotationConditionService.defaultUpdateInterval) {
        motionManager = {
            let manager = CMMotionManager()
            manager.deviceMotionUpdateInterval = withUpdateInterval
            return manager
        }()
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
    }
    
    func start(completion: @escaping(Error?) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            completion(.deviceMotionUnavailable)
            return
        }
        
        guard CMMotionManager.availableAttitudeReferenceFrames().contains(.xArbitraryZVertical) else {
            completion(.attitudeReferenceFrameUnavailable)
            return
        }
        
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { deviceMotion, error in
            guard let deviceMotion = deviceMotion, error == nil else { return }
            
            // do the updating here
//            self.updateRotationRate(deviceMotion)
            self.updatePitch(deviceMotion)
        }
        
        print("Started motion updates")
    }
    
    func stop() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
//    func pullSamples() {
//        guard let _ = motionManager.deviceMotion, let delegate = delegate else { return }
//
//    }
    
    func updatePitch(_ motion: CMDeviceMotion) {
        let pitch = radiansToDegrees(motion.attitude.pitch)
        delegate?.condition(progress: pitch / 100)
        print("Pitch (along x-axis): \(motion.attitude.pitch)")
    }
    
    private func radiansToDegrees(_ x: Double) -> Double { return x * 180 / Double.pi }
    
}
