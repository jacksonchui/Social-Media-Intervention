//
//  RotationConditionServiceTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/1/21.
//

import XCTest
import Social_Intervention

class AngleConditionServiceTests: XCTestCase {

    func test_init_setsUpMotionManagerAndQueue() {
        let (sut, _) = makeSUT()
        
        XCTAssertNotNil(sut.motionManager)
    }
    
    func test_start_failsWhenDeviceMotionUnavailable() {
        let (sut, motionManager) = makeSUT()
        let expectedError: MotionAvailabilityError = .deviceMotionUnavailable
                
        expect(sut, toCompleteWith: expectedError) {
            motionManager.complete(with: expectedError)
        }
    }
    
    func test_checkAvailability_failsWhenAttitudeReferenceFrameUnavailable() {
        let (sut, motionManager) = makeSUT()
        let expectedError: MotionAvailabilityError = .attitudeReferenceFrameUnavailable
        
        expect(sut, toCompleteWith: expectedError) {
            motionManager.complete(with: expectedError)
        }
    }
    
    func test_checkAvailability_nilIfNoCheckErrors() {
        let (sut, motionManager) = makeSUT()
        
        expect(sut, toCompleteWith: nil) {
            motionManager.completeWithNoCheckErrors()
        }
    }
    
    func test_start_BeginsTimer() {
        let (sut, motionManager) = makeSUT()
        
        expect(sut, toCompleteWith: nil) {
            motionManager.completeWithNoCheckErrors()
        }
        
        sut.start()
        
        motionManager.completeStartMotionUpdatesWithNoErrors()
        
        XCTAssertGreaterThan(sut.currentSessionTime, -1)
    }

    // MARK: - Helpers
    func makeSUT(updateInterval: TimeInterval = 1.0) -> (AngleConditionService, MotionManagerSpy) {
        let motionManager = MotionManagerSpy(updateInterval: updateInterval)
        let sut = AngleConditionService(with: motionManager, every: updateInterval)
        
        return (sut, motionManager)
    }
    
    func expect(_ sut: AngleConditionService, toCompleteWith expectedError: MotionAvailabilityError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for start completion")
        
        sut.check { error in
            if let error = error {
                XCTAssertEqual(error, expectedError)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    class MotionManagerSpy: MotionManager {
        
        init(updateInterval: TimeInterval) { }
        
        typealias AvailabilityCompletion = (MotionAvailabilityError?) -> Void
        typealias StartCompletion = DeviceMotionHandler
        
        var availabilityCompletions = [AvailabilityCompletion]()
        var startCompletions = [StartCompletion]()
        
        var initialMotionAttitude: MotionAttitude?
        
        func checkAvailability(completion: @escaping (MotionAvailabilityError?) -> Void) {
            availabilityCompletions.append(completion)
        }
        
        func startMotionUpdates(completion: @escaping DeviceMotionHandler) {
            initialMotionAttitude = MotionAttitude(roll: 0, pitch: 0, yaw: 0)
            startCompletions.append(completion)
        }
        
        func complete(with error: MotionAvailabilityError, at index: Int = 0) {
            availabilityCompletions[index](error)
        }
        
        func completeWithNoCheckErrors(at index: Int = 0) {
            availabilityCompletions[index](nil)
        }
        
        func completeStartMotionUpdatesWithNoErrors(at index: Int = 0) {
            startCompletions[index](initialMotionAttitude, nil)
        }
    }
}
