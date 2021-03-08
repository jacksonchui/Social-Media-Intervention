//
//  RotationConditionServiceTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/1/21.
//

import XCTest
import Social_Intervention

class AttitudeConditionServiceTests: XCTestCase {

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
    
    func test_start_failsOnAnySessionErrorWithNoTimeRecorded() {
        let (sut, manager, _) = makeSUT()
        let expectedError: MotionSessionError = .anyError
        
        expectOnStartSession(sut, toCompleteWith: expectedError, expectedUpdates: 1) {
            manager.completeStartMotionUpdates(with: expectedError)
        }
        XCTAssertEqual(sut.currentPeriodTime, 0.0)
    }
        
    func test_start_storeInitialRecordOnFirstMotionUpdate() {
        let (sut, manager, store) = makeSUT()
        let initialRecord = anyAttitude()
        
        expectOnStartSession(sut, toCompleteWith: nil, expectedUpdates: 1) {
            manager.completeStartMotionUpdates(with: initialRecord)
        }
        XCTAssertEqual(store.records, [initialRecord])
        XCTAssertEqual(sut.initialAttitude, initialRecord)
        XCTAssertEqual(sut.currentPeriodTime, 1.0)
    }
    
    func test_start_storesMultipleRecordsOnMultipleMotionUpdates() {
        let (sut, manager, store) = makeSUT()
        let expectedRecords = anyAttitudes()
        
        expectOnStartSession(sut, toCompleteWith: nil, expectedUpdates: expectedRecords.count) {
            expectedRecords.forEach { manager.completeStartMotionUpdates(with: $0) }
        }
        XCTAssertEqual(store.records, expectedRecords)
        XCTAssertEqual(sut.initialAttitude, expectedRecords.first)
        XCTAssertEqual(sut.currentPeriodTime, 2.0)
    }
    
    func test_start_randomlyGeneratesValidTargetAttitude() {
        let (sut, manager, _) = makeSUT()
        let initialAttitude = anyAttitude()
        let maxRadian = Double.pi/2
        
        expectOnStartSession(sut, toCompleteWith: nil, expectedUpdates: 1) {
            manager.completeStartMotionUpdates(with: initialAttitude)
        }
        
        XCTAssertNotNil(sut.targetAttitude)
        XCTAssertNotEqual(sut.targetAttitude, initialAttitude, "TargetAttitude cannot be the same as InitialAttitude")
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.pitch), maxRadian)
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.yaw), maxRadian)
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.roll), maxRadian)
    }

    // MARK: - Helpers
    
    func makeSUT(updateInterval: TimeInterval = 1.0) -> (AttitudeConditionService, MotionManagerSpy, ConditionStoreSpy) {
        let motionManager = MotionManagerSpy(updateInterval: updateInterval)
        let conditionStore = ConditionStoreSpy()
        let sut = AttitudeConditionService(with: motionManager, saveTo: conditionStore, updateEvery: updateInterval)
        
        return (sut, motionManager, conditionStore)
    }
    
    func expectOnAvailabilityCheck(_ sut: AttitudeConditionService, toCompleteWith expectedError: MotionAvailabilityError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
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
    
    func expectOnStartSession(_ sut: AttitudeConditionService, toCompleteWith expectedError: MotionSessionError?, expectedUpdates count: Int, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

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
        
        var records = [Record]()
        
        func record(_ record: Record) {
            records.append(record)
        }
    }
    
    class MotionManagerSpy: MotionManager {
        
        init(updateInterval: TimeInterval) { }
        
        typealias AvailabilityCompletion = (MotionAvailabilityError?) -> Void
        typealias StartCompletion = DeviceMotionHandler
        
        var availabilityCompletions = [AvailabilityCompletion]()
        var startCompletions = [StartCompletion]()
        
        var initialMotionAttitude: Attitude?
        
        func checkAvailability(completion: @escaping (MotionAvailabilityError?) -> Void) {
            availabilityCompletions.append(completion)
        }
        
        func startMotionUpdates(updatingEvery interval: TimeInterval, completion: @escaping DeviceMotionHandler) {
            initialMotionAttitude = Attitude(roll: 0, pitch: 0, yaw: 0)
            startCompletions.append(completion)
        }
        
        func complete(with error: MotionAvailabilityError, at index: Int = 0) {
            availabilityCompletions[index](error)
        }
        
        func completeWithNoCheckErrors(at index: Int = 0) {
            availabilityCompletions[index](nil)
        }
        
        func completeStartMotionUpdates(with attitude: Attitude, at index: Int = 0) {
            startCompletions[index](.success(attitude))
        }
        
        func completeStartMotionUpdates(with error: MotionSessionError, at index: Int = 0) {
            startCompletions[index](.failure(error))
        }
    }
    
    func anyAttitude() -> Attitude {
        return Attitude(roll: 0, pitch: 0, yaw: 0)
    }
    
    func anyOtherAttitude() -> Attitude {
        return Attitude(roll: 3, pitch: 4, yaw: 5)
    }
    
    func anyAttitudes() -> [Attitude] {
        return [anyAttitude(), anyOtherAttitude()]
    }
}
