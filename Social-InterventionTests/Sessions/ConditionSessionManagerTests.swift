//
//  ConditionSessionManagerTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/10/21.
//

import XCTest

class ConditionSessionManagerTests: XCTestCase {
    func test_init_setsConditionServiceAndResetsPeriodCount() {
        let (sut, _) = makeSUT()
        
        XCTAssertNotNil(sut.service)
        XCTAssertEqual(sut.periodIntervals, 1)
    }
    
    func test_check_deliverErrorOnDeviceMotionUnavailable() {
        let (sut, service) = makeSUT()
        let expectedError: SessionCheckError = .deviceMotionUnavailable
        
        expect(sut, toCompleteCheckWith: expectedError) {
            service.completeCheck(with: expectedError)
        }
    }
    
    func test_check_deliverErrorOnReferenceFrameUnavailable() {
        let (sut, service) = makeSUT()
        let expectedError: SessionCheckError = .attitudeReferenceFrameUnavailable
        
        expect(sut, toCompleteCheckWith: expectedError) {
            service.completeCheck(with: expectedError)
        }
    }
    
    func test_start_recordsPeriodLogForSuccessfulPeriodRatio() {
        let (sut, service) = makeSUT()
        let expectedUpdates = anyProgresses(updatesPerPeriod)
        service.periodCompletedRatio = resetProgressThreshold
        
        start(sut, toCompleteWith: nil, forUpdateCount: expectedUpdates.count) {
            expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
        }
        
        XCTAssertEqual(sut.periodIntervals, 1)
        XCTAssertEqual(sut.sessionLog?.periodLogs.map { $0.duration }, [timePerPeriod])
    }
    
    func test_start_recordsOnSuccessfulPeriodRatioAtThresholdAfterUnsuccessfulIntervals() {
        let (sut, service) = makeSUT()
        let expectedUpdates = anyProgresses(updatesPerPeriod)
        let periodIntervals = 2
        let periodDuration = Double(updatesPerPeriod) * timeInterval * Double(periodIntervals)
        let expectedPeriodLog = PeriodLog(progressPerInterval: [belowThreshold(), atThreshold()], duration: periodDuration)
        
        start(sut, toCompleteWith: nil, forUpdateCount: expectedUpdates.count * periodIntervals) {
            expectedPeriodLog.progressPerInterval.forEach { progress in
                service.periodCompletedRatio = progress
                expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            }
        }
        
        XCTAssertEqual(sut.periodIntervals, 1, "Period Intervals were reset")
        XCTAssertEqual(service.currentPeriodTime, 0.0, "Current time was reset")
        XCTAssertEqual(sut.sessionLog?.periodLogs, [expectedPeriodLog])
    }
    
    func test_start_recordsOnSuccessfulPeriodRatioAboveThresholdAfterUnsuccessfulIntervals() {
        let (sut, service) = makeSUT()
        let expectedUpdates = anyProgresses(updatesPerPeriod)
        let (periodIntervals, periodDuration) = period(for: 2)
        let expectedPeriodLog = PeriodLog(progressPerInterval: [belowThreshold(), aboveThreshold()], duration: periodDuration)
        
        start(sut, toCompleteWith: nil, forUpdateCount: expectedUpdates.count * periodIntervals) {
            expectedPeriodLog.progressPerInterval.forEach { progress in
                service.periodCompletedRatio = progress
                expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            }
        }
        
        XCTAssertEqual(sut.periodIntervals, 1, "Period Intervals were reset")
        XCTAssertEqual(service.currentPeriodTime, 0.0, "Current time was reset")
        XCTAssertEqual(sut.sessionLog?.periodLogs, [expectedPeriodLog])
    }
    
    func test_start_hasNoSideEffectsOnPeriodBelowThreshold() {
        let (sut, service) = makeSUT()
        let expectedUpdates = anyProgresses(updatesPerPeriod)
        let (periodIntervals, periodDuration) = period(for: 2)
        let totalUpdates = expectedUpdates.count * periodIntervals
        let expectedPeriodLog = PeriodLog(progressPerInterval: [belowThreshold(), belowThreshold()], duration: periodDuration)
        
        start(sut, toCompleteWith: nil, forUpdateCount: totalUpdates) {
            expectedPeriodLog.progressPerInterval.forEach { progress in
                service.periodCompletedRatio = progress
                expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            }
        }
        
        XCTAssertEqual(sut.periodIntervals, 3, "Period Intervals were reset")
        XCTAssertEqual(service.currentPeriodTime, 120.0, "Current time was reset")
        XCTAssertEqual(sut.sessionLog?.periodLogs, [])
    }


    // MARK: - Helpers
    
    func makeSUT() -> (sut: ConditionSessionManager, service: ConditionServiceSpy) {
        let service = ConditionServiceSpy()
        let session = ConditionSessionManager(using: service)
        
        return (session, service)
    }
    
    func expect(_ sut: ConditionSessionManager, toCompleteCheckWith expectedError: SessionCheckError, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        sut.check { error in
            XCTAssertEqual(expectedError, error, file: file, line: line)
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    func start(_ sut: ConditionSessionManager, toCompleteWith expectedError: ConditionPeriodError?, forUpdateCount expectedUpdatesCount: Int, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        exp.expectedFulfillmentCount = expectedUpdatesCount
        
        sut.start(loggingTo: nil) { result in
            switch result {
                case let .success(alpha: alpha):
                    XCTAssertGreaterThanOrEqual(alpha, 0.0, file: file, line: line)
                    XCTAssertLessThanOrEqual(alpha, 1.0, file: file, line: line)
                case let .failure(error: error):
                    XCTAssertEqual(error, expectedError, file: file, line: line)
            }
            
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    func belowThreshold() -> Double {
        return resetProgressThreshold - 0.01
    }
    
    func atThreshold() -> Double {
        return resetProgressThreshold
    }
    
    func aboveThreshold() -> Double {
        return resetProgressThreshold + 0.01
    }
    
    func period(for intervals: Int) -> (count: Int, duration: Double) {
        let duration = Double(updatesPerPeriod * intervals) * timeInterval
        return (intervals, duration)
    }
}
