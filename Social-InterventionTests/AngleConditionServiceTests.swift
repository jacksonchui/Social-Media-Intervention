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
        motionManager.checkAvailability(of: .xArbitraryZVertical, completion: completion)
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
        let (sut, _) = makeSUT()
        
        XCTAssertNotNil(sut.motionManager)
    }
    
    func test_start_failsWhenDeviceMotionUnavailable() {
        let (sut, motionManager) = makeSUT()
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
    
    func test_start_failsWhenAttitudeReferenceFrameUnavailable() {
        let (sut, motionManager) = makeSUT()
        let expectedError: CoreMotionError = .attitudeReferenceFrameUnavailable
        
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
    
    // MARK: - Helpers
    func makeSUT(updateInterval: TimeInterval = 1.0) -> (AngleConditionService, MotionManagerSpy) {
        let motionManager = MotionManagerSpy(updateInterval: updateInterval)
        let sut = AngleConditionService(with: motionManager)
        
        return (sut, motionManager)
    }
    
}
