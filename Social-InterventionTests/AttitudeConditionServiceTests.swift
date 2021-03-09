//
//  RotationConditionServiceTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/1/21.
//

import XCTest
import Social_Intervention

class AttitudeConditionServiceTests: XCTestCase {

    func test_init_setsUpMotionManager() {
        let (sut, _) = makeSUT()
        XCTAssertNotNil(sut.motionManager)
    }
    
    func test_check_failsWhenDeviceMotionUnavailable() {
        let (sut, manager) = makeSUT()
        let expectedError: MotionAvailabilityError = .deviceMotionUnavailable
                
        expectOnCheck(sut, toCompleteWith: expectedError) {
            manager.complete(with: expectedError)
        }
    }
    
    func test_check_failsWhenAttitudeReferenceFrameUnavailable() {
        let (sut, manager) = makeSUT()
        let expectedError: MotionAvailabilityError = .attitudeReferenceFrameUnavailable
        
        expectOnCheck(sut, toCompleteWith: expectedError) {
            manager.complete(with: expectedError)
        }
    }
    
    func test_check_succeedsWhenNoErrors() {
        let (sut, manager) = makeSUT()
        
        expectOnCheck(sut, toCompleteWith: nil) {
            manager.completeWithNoCheckErrors()
        }
    }
    
    func test_start_failsOnAnySessionErrorAndDoesNotRecordTime() {
        let (sut, manager) = makeSUT()
        let expectedError: MotionSessionError = .startError
        
        expectOnStart(sut, toCompleteWith: expectedError, forExpectedUpdates: 1) {
            manager.completeStartUpdates(with: expectedError)
        }
        XCTAssertEqual(sut.currentPeriodTime, 0.0)
    }
        
    func test_start_storesFirstUpdateAsInitialRecord() {
        let (sut, manager) = makeSUT()
        let initialRecord = anyAttitude()
        
        expectOnStart(sut, toCompleteWith: nil, forExpectedUpdates: 1) {
            manager.completeStartUpdates(with: initialRecord)
        }
        XCTAssertEqual(sut.records.first, initialRecord)
        XCTAssertEqual(sut.currentPeriodTime, 1.0)
    }
    
    func test_start_storesMultipleRecordsOnMultipleUpdates() {
        let (sut, manager) = makeSUT()
        let expectedRecords = anyAttitudes()
        
        expectOnStart(sut, toCompleteWith: nil, forExpectedUpdates: expectedRecords.count) {
            expectedRecords.forEach { manager.completeStartUpdates(with: $0) }
        }
        XCTAssertEqual(sut.records, expectedRecords)
        XCTAssertEqual(sut.currentPeriodTime, 10.0)
    }
    
    func test_start_generatesValidTargetAttitude() {
        let (sut, manager) = makeSUT()
        let initialAttitude = anyAttitude()
        let maxRadian = Double.pi/2
        
        expectOnStart(sut, toCompleteWith: nil, forExpectedUpdates: 1) {
            manager.completeStartUpdates(with: initialAttitude)
        }
        
        XCTAssertNotEqual(sut.targetAttitude, initialAttitude, "TargetAttitude cannot be the same as InitialAttitude")
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.pitch), maxRadian)
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.yaw), maxRadian)
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.roll), maxRadian)
    }
    
    func test_stop_FailsWhenErrorAndDoesNotResetState(){
        let (sut, manager) = makeSUT()
        let attitudeUpdates = anyAttitudes()
        let expectedError: MotionSessionError? = .stopError
        
        expectOnStart(sut, toCompleteWith: nil, forExpectedUpdates: attitudeUpdates.count) {
            attitudeUpdates.forEach { manager.completeStartUpdates(with: $0) }
        }
        
        expectOnStop(sut, toCompleteWith: expectedError) {
            manager.completeStopUpdates(with: expectedError)
        }
        XCTAssertEqual(sut.currentPeriodTime, 1.0 * Double(attitudeUpdates.count))
        XCTAssertNotNil(sut.records.first, "State should not be reset since Manager might still be running.")
        XCTAssertNotNil(sut.targetAttitude, "State should not be reset since Manager might still be running.")
    }
    
    func test_stop_SucceedsWhenNoErrorsAndEndsCurrentPeriod() {
        let (sut, manager) = makeSUT()
        let attitudeUpdates = anyAttitudes()
        let noError: MotionSessionError? = nil
        
        expectOnStart(sut, toCompleteWith: nil, forExpectedUpdates: attitudeUpdates.count) {
            attitudeUpdates.forEach { manager.completeStartUpdates(with: $0) }
        }
        
        expectOnStop(sut, toCompleteWith: noError) {
            manager.completeStopUpdates(with: noError)
        }
        XCTAssertEqual(sut.currentPeriodTime, 0.0)
        XCTAssertTrue(sut.records.isEmpty, "Reset records at the end of period.")
        XCTAssertNil(sut.targetAttitude, "Reset the target attitude to nil at the end of period.")
    }
    
    func test_startUpdates_succesfullyCalculatesValidProgressInAPeriod() {
        let (sut, manager) = makeSUT()
        let attitudeUpdates = anyAttitudes()
        let noError: MotionSessionError? = nil

        expectOnStart(sut, toCompleteWith: noError, forExpectedUpdates: attitudeUpdates.count) {
            attitudeUpdates.forEach { manager.completeStartUpdates(with: $0) }
        }
        expectOnStop(sut, toCompleteWith: noError) {
            manager.completeStopUpdates(with: noError)
        }
    }

    // MARK: - Helpers
    
    func makeSUT(updateInterval: TimeInterval = 1.0) -> (AttitudeConditionService, MotionManagerSpy) {
        let motionManager = MotionManagerSpy(updateInterval: updateInterval)
        let sut = AttitudeConditionService(with: motionManager, updateEvery: updateInterval)
        
        return (sut, motionManager)
    }
    
    func expectOnCheck(_ sut: AttitudeConditionService, toCompleteWith expectedError: MotionAvailabilityError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
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
    
    func expectOnStart(_ sut: AttitudeConditionService, toCompleteWith expectedError: MotionSessionError?, forExpectedUpdates count: Int, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        let exp = expectation(description: "Wait for completion")
        exp.expectedFulfillmentCount = count
        
        sut.start {result in
            switch result {
                case let .failure(error):
                    XCTAssertEqual(error, expectedError)
                case let .success(progress: progress):
                    XCTAssertLessThanOrEqual(progress, 1.0)
                    XCTAssertGreaterThanOrEqual(progress, 0.0)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    func expectOnStop(_ sut: AttitudeConditionService, toCompleteWith expectedError: MotionSessionError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        let exp = expectation(description: "Wait for completion")
        
        sut.stop {result in
            switch result {
                case let .failure(error):
                    XCTAssertEqual(error, expectedError)
                case let .success(progressAboveThreshold: progress):
                    XCTAssertLessThanOrEqual(progress, 1.0)
                    XCTAssertGreaterThanOrEqual(progress, 0.0)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
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
    
    func anyAttitudes(_ count: Int = 10) -> [Attitude] {
        var attitudes = [Attitude]()
        for _ in 0..<10 {
            attitudes.append(randomAttitude)
        }
        return attitudes
    }
    
    private var randomRadian: Double {
        let sigFigures = 2
        return Double.random(in: -Double.pi/2...Double.pi/2).truncate(places: sigFigures)
    }
    
    private var randomAttitude: Attitude { Attitude(roll: randomRadian, pitch: randomRadian, yaw: randomRadian) }
}
