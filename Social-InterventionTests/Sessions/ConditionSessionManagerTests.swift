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
        let (expectedUpdates, duration, updatesPerPeriod) = use(intervals: 1)
        let expectedPeriodLog = PeriodLog(progressPerInterval: [atThreshold()], duration: duration)
        
        service.periodCompletedRatio = resetProgressThreshold
        start(sut, toCompleteWith: nil, for: updatesPerPeriod) {
            expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
        }
        
        XCTAssertEqual(sut.periodIntervals, 1)
        XCTAssertEqual(sut.sessionLog?.periodLogs, [expectedPeriodLog])
    }
    
    func test_start_recordsOnSuccessfulPeriodRatioAtThresholdAfterUnsuccessfulIntervals() {
        let (sut, service) = makeSUT()
        let (expectedUpdates, duration, updatesPerPeriod) = use(intervals: 2)
        let expectedPeriodLog = PeriodLog(progressPerInterval: [belowThreshold(), atThreshold()], duration: duration)
        
        start(sut, toCompleteWith: nil, for: updatesPerPeriod) {
            expectedPeriodLog.progressPerInterval.forEach { progress in
                service.periodCompletedRatio = progress
                expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            }
        }
        
        expectEqual(for: sut, with: service, intervals: 1, time: 0.0, logs: [expectedPeriodLog], "Intervals and time should reset")
    }
    
    func test_start_recordsOnSuccessfulPeriodRatioAboveThresholdAfterUnsuccessfulInterval() {
        let (sut, service) = makeSUT()
        let (expectedUpdates, duration, totalUpdatesPerPeriod) = use(intervals: 2)
        let expectedPeriodLog = PeriodLog(progressPerInterval: [belowThreshold(), aboveThreshold()], duration: duration)
        
        start(sut, toCompleteWith: nil, for: totalUpdatesPerPeriod) {
            expectedPeriodLog.progressPerInterval.forEach { progress in
                service.periodCompletedRatio = progress
                expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            }
        }
        
        expectEqual(for: sut, with: service, intervals: 1, time: 0.0, logs: [expectedPeriodLog], "Intervals and time should reset")
    }
    
    func test_start_hasNoSideEffectsOnPeriodBelowThreshold() {
        let (sut, service) = makeSUT()
        let (expectedUpdates, duration, updatesPerPeriod) = use(intervals: 2)
        let expectedPeriodLog = PeriodLog(progressPerInterval: [belowThreshold(), belowThreshold()], duration: duration)
        
        start(sut, toCompleteWith: nil, for: updatesPerPeriod) {
            expectedPeriodLog.progressPerInterval.forEach { progress in
                service.periodCompletedRatio = progress
                expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            }
        }
        
        expectEqual(for: sut, with: service, intervals: 3, time: duration, logs: [], "Intervals and time shouldn't reset")
    }
    
    func test_start_recordsOnSuccessfulPeriodRatiosForTwoFullPeriods() {
        let (sut, service) = makeSUT()
        let (expectedUpdates, duration, updatesPerPeriod) = use(intervals: 3)
        let progressLog = [belowThreshold(), belowThreshold(), aboveThreshold()]
        
        let expectedPeriodLog = PeriodLog(progressPerInterval: progressLog, duration: duration)
        let updatesForTwoPeriods = updatesPerPeriod * 2
        
        start(sut, toCompleteWith: nil, for: updatesForTwoPeriods) {
            expectedPeriodLog.progressPerInterval.forEach { progress in
                service.periodCompletedRatio = progress
                expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            }
            
            expectedPeriodLog.progressPerInterval.forEach { progress in
                service.periodCompletedRatio = progress
                expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            }
        }
        
        expectEqual(for: sut, with: service, intervals: 1, time: 0.0, logs: [expectedPeriodLog, expectedPeriodLog], "Intervals and time should reset")
    }
    
    func test_stop_recordsLatestProgressBeforeEndingSession() {
        let (sut, service) = makeSUT()
        let updatesBeforeStop = updatesPerPeriodInterval - 1
        let (expectedUpdates, duration, totalUpdates) = use(updatesBeforeStop, intervals: 1)
        let expectedPeriodLog = PeriodLog(progressPerInterval: [belowThreshold()], duration: duration)
        
        start(sut, toCompleteWith: nil, for: totalUpdates) {
            expectedPeriodLog.progressPerInterval.forEach { progress in
                service.periodCompletedRatio = progress
                expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            }
        }
        
        expect(sut, toCompleteStopWith: nil) {
            service.completeStopSuccessfully()
        }
        expectEqual(for: sut, with: service, intervals: 1, time: 0.0, logs: [expectedPeriodLog], "Intervals and time should reset")
    }

    // MARK: - Helpers
    
    func makeSUT() -> (sut: ConditionSessionManager, service: ConditionServiceSpy) {
        let service = ConditionServiceSpy()
        let session = ConditionSessionManager(using: service)
        
        return (session, service)
    }
    
    func expect(_ sut: ConditionSessionManager, toCompleteStopWith expectedError: SessionStopError, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        sut.stop { error in
            if let error = error {
                XCTAssertEqual(expectedError, error, file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    func expect(_ sut: ConditionSessionManager, toCompleteCheckWith expectedError: SessionCheckError, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        sut.check { error in
            if let error = error {
                XCTAssertEqual(expectedError, error, file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    func start(_ sut: ConditionSessionManager, toCompleteWith expectedError: ConditionPeriodError?, for expectedUpdatesCount: Int, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
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
        
    func use(_ updatesPerInterval: Int = updatesPerPeriodInterval, intervals: Int)
            -> (progressUpdates: [Double], periodDuration: Double, totalPeriodUpdates: Int) {
        let progressUpdates = anyProgresses(updatesPerInterval)
        let totalPeriodUpdates = updatesPerInterval * intervals
        let periodDuration = Double(totalPeriodUpdates) * timeInterval

        return (progressUpdates, periodDuration, totalPeriodUpdates)
    }
    
    func expectEqual(for sut: ConditionSessionManager, with service: ConditionService, intervals expectedIntervals: Int, time expectedCurrPeriodTime: Double, logs expectedPeriodLogs: [PeriodLog], _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(sut.periodIntervals, expectedIntervals, file: file, line: line)
        XCTAssertEqual(service.currentPeriodTime, expectedCurrPeriodTime, file: file, line: line)
        XCTAssertEqual(sut.sessionLog?.periodLogs, expectedPeriodLogs, file: file, line: line)
    }
}
