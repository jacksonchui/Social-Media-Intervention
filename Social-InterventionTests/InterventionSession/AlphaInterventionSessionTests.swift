//
//  ViewAlphaInterventionSessionTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/10/21.
//

import XCTest

class ViewAlphaInterventionSessionTests: XCTestCase {
    func test_init_setsConditionServiceAndResetsPeriodCount() {
        let (sut, _, _ ) = makeSUT()
        
        XCTAssertNotNil(sut.service)
        XCTAssertEqual(sut.periodCount, 1)
    }
    
    func test_check_deliverErrorOnDeviceMotionUnavailable() {
        let (sut, service, _) = makeSUT()
        let expectedError: ViewAlphaInterventionSession.CheckError = .deviceMotionUnavailable
        
        expectOnCheck(sut, toCompleteWith: expectedError) {
            service.completeCheck(with: expectedError)
        }
    }
    
    func test_check_deliverErrorOnReferenceFrameUnavailable() {
        let (sut, service, _) = makeSUT()
        let expectedError: ViewAlphaInterventionSession.CheckError = .attitudeReferenceFrameUnavailable
        
        expectOnCheck(sut, toCompleteWith: expectedError) {
            service.completeCheck(with: expectedError)
        }
    }

    func test_start_deliversAlphaOnEachUpdateForOnePeriodSuccessfully() {
        let (sut, service, _) = makeSUT()
        let expectedUpdates = anyProgresses(updatesPerPeriod)
        
        expectOnStart(sut, toCompleteWith: nil, for: expectedUpdates.count) {
            expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
        }
    }
    
    func test_start_succeedsWhenProgressThresholdMetForOnePeriod() {
        let (sut, service, _) = makeSUT()
        let expectedUpdates = anyProgresses(updatesPerPeriod)
        service.progressAboveThreshold = resetProgressThreshold
        
        expectOnStart(sut, toCompleteWith: nil, for: expectedUpdates.count) {
            expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
        }
        
        XCTAssertEqual(sut.periodCount, 1)
        XCTAssertEqual(service.currentPeriodTime, 0.0)
        XCTAssertEqual(sut.sessionLog.map { $0.periodDuration }, [timePerPeriod])
    }
    
    func test_start_succeedsOnlyWhenProgressThresholdMetAcrossMultiplePeriods() {
        let (sut, service, _) = makeSUT()
        let expectedUpdates = anyProgresses(updatesPerPeriod)
        let timePerPeriod: Double = Double(updatesPerPeriod) * timeInterval
        
        expectOnStart(sut, toCompleteWith: nil, for: expectedUpdates.count * 5) {
            
            // first period
            let expectedLogEntry1 = SessionLogEntry(progressOverPeriod: [resetProgressThreshold - 0.01, resetProgressThreshold], periodDuration: timePerPeriod * 2)
            
            service.progressAboveThreshold = resetProgressThreshold - 0.01
            expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            
            XCTAssertEqual(sut.periodCount, 2)
            XCTAssertEqual(service.currentPeriodTime, timePerPeriod)
            XCTAssertEqual(sut.sessionLog, [])
            
            service.progressAboveThreshold = resetProgressThreshold
            expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            
            XCTAssertEqual(sut.periodCount, 1)
            XCTAssertEqual(service.currentPeriodTime, 0.0)
            XCTAssertEqual(sut.sessionLog, [expectedLogEntry1])
            
            // second period
            let expectedLogEntry2 = SessionLogEntry(progressOverPeriod: [resetProgressThreshold - 0.01, resetProgressThreshold - 0.01, resetProgressThreshold + 0.01], periodDuration: timePerPeriod * 3)
            
            service.progressAboveThreshold = resetProgressThreshold - 0.01
            expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            
            XCTAssertEqual(sut.periodCount, 2)
            XCTAssertEqual(service.currentPeriodTime, timePerPeriod)
            XCTAssertEqual(sut.sessionLog, [expectedLogEntry1])
            
            service.progressAboveThreshold = resetProgressThreshold - 0.01
            expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            
            XCTAssertEqual(sut.periodCount, 3)
            XCTAssertEqual(service.currentPeriodTime, timePerPeriod * 2)
            XCTAssertEqual(sut.sessionLog, [expectedLogEntry1])
            
            service.progressAboveThreshold = resetProgressThreshold + 0.01
            expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
            
            XCTAssertEqual(sut.periodCount, 1)
            XCTAssertEqual(service.currentPeriodTime, 0.0)
            XCTAssertEqual(sut.sessionLog, [expectedLogEntry1, expectedLogEntry2])
        }
    }


    // MARK: - Helpers
    
    func makeSUT() -> (sut: ViewAlphaInterventionSession, service: ConditionServiceSpy, analytics: SIAnalyticsController) {
        let service = ConditionServiceSpy()
        let analytics = SIAnalyticsController()
        let session = ViewAlphaInterventionSession(using: service, sendsLogTo: analytics)
        
        return (session, service, analytics)
    }
    
    func expectOnCheck(_ sut: ViewAlphaInterventionSession, toCompleteWith expectedError: ViewAlphaInterventionSession.CheckError, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        
        sut.check { error in
            XCTAssertEqual(expectedError, error, file: file, line: line)
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    func expectOnStart(_ sut: ViewAlphaInterventionSession, toCompleteWith expectedError: ConditionPeriodError?, for expectedUpdatesCount: Int, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        exp.expectedFulfillmentCount = expectedUpdatesCount
        
        sut.start { result in
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
}
