//
//  AttitudeConditionServiceTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/1/21.
//

import XCTest
import Social_Intervention

class AttitudeConditionServiceTests: XCTestCase {

    func test_init_createsAttitudeClientToGetMotionUpdatesFrom() {
        let (sut, _) = makeSUT()
        XCTAssertNotNil(sut.attitudeClient)
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
    
    func test_reset_setsRecordsToEmptyAndTargetAttitudeToNil() {
        let (sut, _) = makeSUT()
        sut.reset()
        
        XCTAssertEqual(sut.currPeriodDuration, 0.0)
        XCTAssertNil(sut.targetAttitude)
    }
        
    func test_check_succeedsWhenNoErrors() {
        let (sut, manager) = makeSUT()
        
        expectOnCheck(sut, toCompleteWith: nil) {
            manager.completeWithNoCheckErrors()
        }
    }
    
    func test_start_failsOnAnySessionErrorAndDoesNotRecordTime() {
        let (sut, manager) = makeSUT()
        let expectedError = anyNSError("Failed to start motion updates")
        
        expectOnStart(sut, toCompleteWith: expectedError, forExpectedUpdates: 1) {
            manager.completeStartUpdates(with: expectedError)
        }
        XCTAssertEqual(sut.currPeriodDuration, 0.0)
    }
        
    func test_start_storesFirstUpdateAsInitialRecord() {
        let (sut, manager) = makeSUT()
        let initialRecord = anyAttitude()
        
        expectOnStart(sut, toCompleteWith: nil, forExpectedUpdates: 1) {
            manager.completeStartUpdatesSuccessfully(with: initialRecord)
        }
        XCTAssertEqual(sut.records.first, initialRecord)
        XCTAssertEqual(sut.currPeriodDuration, 1.0)
    }
    
    func test_start_storesMultipleRecordsOnMultipleUpdates() {
        let (sut, manager) = makeSUT()
        let expectedRecords = anyAttitudes()
        
        expectOnStart(sut, toCompleteWith: nil, forExpectedUpdates: expectedRecords.count) {
            expectedRecords.forEach { manager.completeStartUpdatesSuccessfully(with: $0) }
        }
        XCTAssertEqual(sut.records, expectedRecords)
        XCTAssertEqual(sut.currPeriodDuration, 10.0)
    }
    
    func test_start_generatesValidTargetAttitude() {
        let (sut, manager) = makeSUT()
        let initialAttitude = anyAttitude()
        let maxRadian = Double.pi/2
        
        expectOnStart(sut, toCompleteWith: nil, forExpectedUpdates: 1) {
            manager.completeStartUpdatesSuccessfully(with: initialAttitude)
        }
        
        XCTAssertNotEqual(sut.targetAttitude, initialAttitude, "TargetAttitude cannot be the same as InitialAttitude")
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.pitch), maxRadian)
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.yaw), maxRadian)
        XCTAssertLessThanOrEqual(abs(sut.targetAttitude!.roll), maxRadian)
    }
    
    func test_start_recordsUpdatesThenResetThenRecordsMoreUpdatesSuccessfully() {
        let (sut, manager) = makeSUT()
        let attitudeUpdates = anyAttitudes(100)
        
        expectOnStart(sut, toCompleteWith: nil, forExpectedUpdates: attitudeUpdates.count * 2) {
            attitudeUpdates.forEach { manager.completeStartUpdatesSuccessfully(with: $0) }
            XCTAssertEqual(sut.records, attitudeUpdates)
            
            sut.reset()
            XCTAssertTrue(sut.records.isEmpty, "Reset records at the end of period if threshold is met.")
            XCTAssertNil(sut.targetAttitude, "Reset the target attitude to nil at the end of period if threshold is met.")
            
            attitudeUpdates.forEach { manager.completeStartUpdatesSuccessfully(with: $0) }
            XCTAssertEqual(sut.records, attitudeUpdates)
        }
    }

    // MARK: - Helpers
    
    func makeSUT(updateInterval: TimeInterval = 1.0) -> (AttitudeConditionService, AttitudeMotionClientSpy) {
        let motionClient = AttitudeMotionClientSpy(updateInterval: updateInterval)
        let sut = AttitudeConditionService(with: motionClient, updateEvery: updateInterval)
        trackForMemoryLeaks(motionClient)
        trackForMemoryLeaks(sut)
        return (sut, motionClient)
    }
    
    func expectOnCheck(_ sut: AttitudeConditionService, toCompleteWith expectedError: MotionAvailabilityError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for start completion")
        
        sut.check { error in
            if let error = error {
                XCTAssertEqual(error, expectedError, file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    func expectOnStart(_ sut: AttitudeConditionService, toCompleteWith expectedError: NSError?, forExpectedUpdates count: Int, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        let exp = expectation(description: "Wait for completion")
        exp.expectedFulfillmentCount = count
        
        sut.start {result in
            switch result {
                case let .success(progressUpdate: progress):
                    XCTAssertGreaterThanOrEqual(progress, 0.0, file: file, line: line)
                    XCTAssertLessThanOrEqual(progress, 1.0, file: file, line: line)
                case let .failure(error):
                    XCTAssertEqual(error as NSError, expectedError, file: file, line: line)
                case .alreadyStarted:
                    XCTFail("Should not try to start twice")
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    func stop(_ sut: AttitudeConditionService, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        let exp = expectation(description: "Wait for completion")
        
        sut.stop {result in
            switch result {
                case .stopped, .alreadyStopped:
                    break
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
}
