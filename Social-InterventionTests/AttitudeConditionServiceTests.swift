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
        let expectedError: MotionSessionError = .startError
        
        expectStartPeriod(sut, toCompleteWith: expectedError, forExpectedUpdates: 1) {
            manager.completeStartUpdates(with: expectedError)
        }
        XCTAssertEqual(sut.currentPeriodTime, 0.0)
    }
        
    func test_start_storeInitialRecordOnFirstMotionUpdateSuccessfully() {
        let (sut, manager, store) = makeSUT()
        let initialRecord = anyAttitude()
        
        expectStartPeriod(sut, toCompleteWith: nil, forExpectedUpdates: 1) {
            manager.completeStartUpdates(with: initialRecord)
        }
        XCTAssertEqual(store.records, [initialRecord])
        XCTAssertEqual(sut.initialAttitude, initialRecord)
        XCTAssertEqual(sut.currentPeriodTime, 1.0)
    }
    
    func test_start_storesMultipleRecordsOnMultipleMotionUpdatesSuccessfully() {
        let (sut, manager, store) = makeSUT()
        let expectedRecords = anyAttitudes()
        
        expectStartPeriod(sut, toCompleteWith: nil, forExpectedUpdates: expectedRecords.count) {
            expectedRecords.forEach { manager.completeStartUpdates(with: $0) }
        }
        XCTAssertEqual(store.records, expectedRecords)
        XCTAssertEqual(sut.initialAttitude, expectedRecords.first)
        XCTAssertEqual(sut.currentPeriodTime, 2.0)
    }
    
    func test_start_randomlyGeneratesValidTargetAttitudeSuccessfully() {
        let (sut, manager, _) = makeSUT()
        let initialAttitude = anyAttitude()
        let maxRadian = Double.pi/2
        
        expectStartPeriod(sut, toCompleteWith: nil, forExpectedUpdates: 1) {
            manager.completeStartUpdates(with: initialAttitude)
        }
        
        XCTAssertNotNil(sut.targetAttitude)
        XCTAssertNotEqual(sut.targetAttitude, initialAttitude, "TargetAttitude cannot be the same as InitialAttitude")
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.pitch), maxRadian)
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.yaw), maxRadian)
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.roll), maxRadian)
    }
    
    func test_start_thenUpdates_thenStopWithError_doesNotResetState(){
        let (sut, manager, _) = makeSUT()
        let attitudeUpdates = anyAttitudes()
        let expectedError: MotionSessionError? = .stopError
        
        expectStartPeriod(sut, toCompleteWith: nil, forExpectedUpdates: attitudeUpdates.count) {
            attitudeUpdates.forEach { manager.completeStartUpdates(with: $0) }
        }
        
        expectStopPeriod(sut, toCompleteWith: expectedError) {
            manager.completeStopUpdates(with: expectedError)
        }
        XCTAssertEqual(sut.currentPeriodTime, 1.0 * Double(attitudeUpdates.count))
        XCTAssertNotNil(sut.initialAttitude, "State should not be reset since Manager might still be running.")
        XCTAssertNotNil(sut.targetAttitude, "State should not be reset since Manager might still be running.")
    }
    
    func test_start_thenUpdates_thenStop_endsCurrentPeriodSuccessfully() {
        let (sut, manager, _) = makeSUT()
        let attitudeUpdates = anyAttitudes()
        let noError: MotionSessionError? = nil
        
        expectStartPeriod(sut, toCompleteWith: nil, forExpectedUpdates: attitudeUpdates.count) {
            attitudeUpdates.forEach { manager.completeStartUpdates(with: $0) }
        }
        
        expectStopPeriod(sut, toCompleteWith: noError) {
            manager.completeStopUpdates(with: noError)
        }
        XCTAssertEqual(sut.currentPeriodTime, 0.0)
        XCTAssertNil(sut.initialAttitude, "Reset the initial attitude to nil at the end of period.")
        XCTAssertNil(sut.targetAttitude, "Reset the target attitude to nil at the end of period.")
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
    
    func expectStartPeriod(_ sut: AttitudeConditionService, toCompleteWith expectedError: MotionSessionError?, forExpectedUpdates count: Int, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

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
    
    func expectStopPeriod(_ sut: AttitudeConditionService, toCompleteWith expectedError: MotionSessionError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        let exp = expectation(description: "Wait for completion")
        
        sut.stop {error in
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
                
        var availabilityCompletions = [AvailabilityCompletion]()
        var startCompletions = [StartCompletion]()
        var stopCompletions = [StopCompletion]()
        
        var initialAttitude: Attitude?
        
        func checkAvailability(completion: @escaping (MotionAvailabilityError?) -> Void) {
            availabilityCompletions.append(completion)
        }
        
        func startUpdates(updatingEvery interval: TimeInterval, completion: @escaping StartCompletion) {
            initialAttitude = Attitude(roll: 0, pitch: 0, yaw: 0)
            startCompletions.append(completion)
        }
        
        func stopUpdates(completion: @escaping StopCompletion) {
            stopCompletions.append(completion)
        }
        
        func complete(with error: MotionAvailabilityError, at index: Int = 0) {
            availabilityCompletions[index](error)
        }
        
        func completeWithNoCheckErrors(at index: Int = 0) {
            availabilityCompletions[index](nil)
        }
        
        func completeStartUpdates(with attitude: Attitude, at index: Int = 0) {
            startCompletions[index](.success(attitude))
        }
        
        func completeStartUpdates(with error: MotionSessionError, at index: Int = 0) {
            startCompletions[index](.failure(error))
        }
        
        func completeStopUpdates(with error: MotionSessionError?, at index: Int = 0) {
            stopCompletions[index](error)
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
