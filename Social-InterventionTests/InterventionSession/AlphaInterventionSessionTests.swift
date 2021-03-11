//
//  AlphaInterventionSessionTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/10/21.
//

import XCTest

class AlphaInterventionSession {
    
    public typealias CheckError = MotionAvailabilityError
    public typealias CheckCompletion = (CheckError?) -> Void
    
    private(set) var service: ConditionServiceSpy
    private(set) var periodCount: Int
    
    init(using service: ConditionServiceSpy) {
        self.service = service
        periodCount = 1
    }
    
    public func check(completion: @escaping CheckCompletion) {
        service.check(completion: completion)
    }
    
    private func resetPeriodCount() { periodCount = 1 }
}

class ConditionServiceSpy: ConditionService {
    var currentPeriodTime: TimeInterval
    var progressAboveThreshold: Double
    
    var checkCompletions = [CheckCompletion]()
    
    init() {
        currentPeriodTime = 0
        progressAboveThreshold = 0
    }
    
    func check(completion: @escaping CheckCompletion) {
        checkCompletions.append(completion)
    }
    
    func start(completion: @escaping StartCompletion) { }
    
    func stop(completion: @escaping StopCompletion) { }
    
    func reset() { }
    
    func completeCheck(with error: InterventionSession.CheckError, at index: Int = 0) {
        checkCompletions[index](error)
    }
}

class AlphaInterventionSessionTests: XCTestCase {
    func test_init_setsConditionServiceAndResetsPeriodCount() {
        let (sut, _ ) = makeSUT()
        
        XCTAssertNotNil(sut.service)
        XCTAssertEqual(sut.periodCount, 1)
    }
    
    func test_check_deliverErrorOnDeviceMotionUnavailable() {
        let (sut, service) = makeSUT()
        let expectedError: AlphaInterventionSession.CheckError = .deviceMotionUnavailable
        
        expectOnCheck(sut, toCompleteWith: expectedError) {
            service.completeCheck(with: expectedError)
        }
    }
    
    func test_check_deliverErrorOnReferenceFrameUnavailable() {
        let (sut, service) = makeSUT()
        let expectedError: AlphaInterventionSession.CheckError = .attitudeReferenceFrameUnavailable
        
        expectOnCheck(sut, toCompleteWith: expectedError) {
            service.completeCheck(with: expectedError)
        }
    }
    
    // MARK: - Helpers
    
    func makeSUT() -> (sut: AlphaInterventionSession, service: ConditionServiceSpy) {
        let service = ConditionServiceSpy()
        let session = AlphaInterventionSession(using: service)
        
        return (session, service)
    }
    
    func expectOnCheck(_ sut: AlphaInterventionSession, toCompleteWith expectedError: AlphaInterventionSession.CheckError, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        
        sut.check { error in
            XCTAssertEqual(expectedError, error, file: file, line: line)
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    
}
