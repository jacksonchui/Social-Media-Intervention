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
        let (sut, _, _) = makeSUT()
        
        XCTAssertNotNil(sut.motionManager)
    }
    
    func test_start_failsWhenDeviceMotionUnavailable() {
        let (sut, motionManager, _) = makeSUT()
        let expectedError: MotionAvailabilityError = .deviceMotionUnavailable
                
        expectOnAvailabilityCheck(sut, toCompleteWith: expectedError) {
            motionManager.complete(with: expectedError)
        }
    }
    
    func test_checkAvailability_failsWhenAttitudeReferenceFrameUnavailable() {
        let (sut, motionManager, _) = makeSUT()
        let expectedError: MotionAvailabilityError = .attitudeReferenceFrameUnavailable
        
        expectOnAvailabilityCheck(sut, toCompleteWith: expectedError) {
            motionManager.complete(with: expectedError)
        }
    }
    
    func test_checkAvailability_nilIfNoCheckErrors() {
        let (sut, motionManager, _) = makeSUT()
        
        expectOnAvailabilityCheck(sut, toCompleteWith: nil) {
            motionManager.completeWithNoCheckErrors()
        }
    }
    
    func test_start_BeginsTimer() {
        let (sut, motionManager, _) = makeSUT()
        
        expectOnAvailabilityCheck(sut, toCompleteWith: nil) {
            motionManager.completeWithNoCheckErrors()
        }
        
        sut.start { _ in }
        
        motionManager.completeStartMotionUpdates(using: anyMotionAttitude())
        
        XCTAssertGreaterThan(sut.currentSessionTime, -1)
    }
    
    func test_start_storesOneRecordInConditionStore() {
        let (sut, manager, store) = makeSUT()
        let expectedAttitude = anyMotionAttitude()
        
        expectOnStartSession(sut, toCompleteWith: nil, expectedUpdates: 1) {
            manager.completeStartMotionUpdates(using: expectedAttitude)
        }
        XCTAssertEqual(store.progressMessages, [expectedAttitude])
    }
    
    func test_start_storesMultipleRecordsInConditionStore() {
        let (sut, manager, store) = makeSUT()
        let expectedAttitudes = anyMotionAttitudes()
        
        expectOnStartSession(sut, toCompleteWith: nil, expectedUpdates: expectedAttitudes.count) {
            expectedAttitudes.forEach { manager.completeStartMotionUpdates(using: $0) }
        }
        XCTAssertEqual(store.progressMessages, expectedAttitudes)
    }

    // MARK: - Helpers
    
    func makeSUT(updateInterval: TimeInterval = 1.0) -> (AngleConditionService, MotionManagerSpy, ConditionStoreSpy) {
        let motionManager = MotionManagerSpy(updateInterval: updateInterval)
        let conditionStore = ConditionStoreSpy()
        let sut = AngleConditionService(with: motionManager, savingTo: conditionStore, every: updateInterval)
        
        return (sut, motionManager, conditionStore)
    }
    
    func expectOnAvailabilityCheck(_ sut: AngleConditionService, toCompleteWith expectedError: MotionAvailabilityError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
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
    
    func expectOnStartSession(_ sut: AngleConditionService, toCompleteWith expectedError: MotionSessionError?, expectedUpdates count: Int, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        let exp = expectation(description: "Wait for completion")
        exp.expectedFulfillmentCount = count
        
        sut.start {error in
            if let error = error {
                XCTAssertEqual(error, expectedError)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    class ConditionStoreSpy: ConditionStore {
        
        var progressMessages = [Record]()
        
        func record(_ progress: Record) {
            progressMessages.append(progress)
        }
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
        
        func completeStartMotionUpdates(using attitude: MotionAttitude, at index: Int = 0) {
            startCompletions[index](.success(attitude))
        }
    }
    
    func anyMotionAttitude() -> MotionAttitude {
        return MotionAttitude(roll: 3, pitch: 4, yaw: 5)
    }
    
    func anyMotionAttitudes() -> [MotionAttitude] {
        return [anyMotionAttitude(), anyMotionAttitude()]
    }
}
