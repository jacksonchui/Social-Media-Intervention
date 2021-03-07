//
//  RotationConditionServiceTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/1/21.
//

import XCTest

import CoreMotion

enum MotionError: String, Swift.Error {
    case deviceMotionUnavailable = "Device Motion is unavailable"
    case attitudeReferenceFrameUnavailable = "Could not get the desired motion frame for device"
}

class AngleConditionService {
    
    
    
    private(set) var motionManager: MotionManagerSpy
    
    init(with motionManager: MotionManagerSpy) {
        self.motionManager = motionManager
    }
    
    func start(completion: @escaping (MotionError?) -> Void) {
        motionManager.checkAvailability(of: .xArbitraryZVertical, completion: completion)
    }
}

class MotionManagerSpy {
    
    
    init(updateInterval: TimeInterval) { }
    
    typealias AvailabilityCompletion = (MotionError?) -> Void
    
    var availabilityCompletions = [AvailabilityCompletion]()
    
    func checkAvailability(of attitude: CMAttitudeReferenceFrame, completion: @escaping (MotionError?) -> Void) {
        availabilityCompletions.append(completion)
    }
    
    func complete(with error: MotionError, at index: Int = 0) {
        availabilityCompletions[index](error)
    }
    
    func completeWithNoStartupErrors(at index: Int = 0) {
        availabilityCompletions[index](nil)
    }
}

class AngleConditionServiceTests: XCTestCase {

    func test_init_setsUpMotionManagerAndQueue() {
        let (sut, _) = makeSUT()
        
        XCTAssertNotNil(sut.motionManager)
    }
    
    func test_start_failsWhenDeviceMotionUnavailable() {
        let (sut, motionManager) = makeSUT()
        let expectedError: MotionError = .deviceMotionUnavailable
                
        expect(sut, toCompleteWith: expectedError) {
            motionManager.complete(with: expectedError)
        }
    }
    
    func test_start_failsWhenAttitudeReferenceFrameUnavailable() {
        let (sut, motionManager) = makeSUT()
        let expectedError: MotionError = .attitudeReferenceFrameUnavailable
        
        expect(sut, toCompleteWith: expectedError) {
            motionManager.complete(with: expectedError)
        }
    }
    
    func test_start_startsUpdatesWithNoError() {
        let (sut, motionManager) = makeSUT()
        
        expect(sut, toCompleteWith: nil) {
            motionManager.completeWithNoStartupErrors()
        }
    }
    
    // MARK: - Helpers
    func makeSUT(updateInterval: TimeInterval = 1.0) -> (AngleConditionService, MotionManagerSpy) {
        let motionManager = MotionManagerSpy(updateInterval: updateInterval)
        let sut = AngleConditionService(with: motionManager)
        
        return (sut, motionManager)
    }
    
    func expect(_ sut: AngleConditionService, toCompleteWith expectedError: MotionError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for start completion")
        
        sut.start { error in
            if let error = error {
                XCTAssertEqual(error, expectedError)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
}
