//
//  RotationConditionServiceTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/1/21.
//

import XCTest

import CoreMotion

enum CoreMotionError: String, Swift.Error {
    case deviceMotionUnavailable = "Device Motion is unavailable"
    case attitudeReferenceFrameUnavailable = "Could not get the desired motion frame for device"
}

class AngleConditionService {
    
    
    
    private(set) var motionManager: MotionManagerSpy
    
    init(with motionManager: MotionManagerSpy) {
        self.motionManager = motionManager
    }
    
    func start(completion: @escaping (CoreMotionError?) -> Void) {
        motionManager.checkAvailability(of: .xArbitraryZVertical) { error in
            if let error = error {
                completion(error)
                return
            }
        }
    }
}

class MotionManagerSpy {
    
    
    init(updateInterval: TimeInterval) { }
    
    typealias AvailabilityCompletion = (CoreMotionError?) -> Void
    
    var availabilityCompletions = [AvailabilityCompletion]()
    
    func checkAvailability(of attitude: CMAttitudeReferenceFrame, completion: @escaping (CoreMotionError?) -> Void) {
        availabilityCompletions.append(completion)
    }
    
    func complete(with error: CoreMotionError, at index: Int = 0) {
        availabilityCompletions[index](error)
    }
}

class AngleConditionServiceTests: XCTestCase {

    func test_init_setsUpMotionManagerAndQueue() {
        let motionManager = MotionManagerSpy(updateInterval: 1.0)
        let sut = AngleConditionService(with: motionManager)
        
        XCTAssertNotNil(sut.motionManager)
    }
    
    func test_start_failsWhenDeviceMotionUnavailable() {
        let motionManager = MotionManagerSpy(updateInterval: 1.0)
        let sut = AngleConditionService(with: motionManager)
        let expectedError: CoreMotionError = .deviceMotionUnavailable
        
        let exp = expectation(description: "Wait for completion")
        
        sut.start { error in
            if let error = error {
                XCTAssertEqual(error, expectedError)
            }
            exp.fulfill()
        }
        
        motionManager.complete(with: expectedError)
        
        wait(for: [exp], timeout: 1.0)
    }
}
