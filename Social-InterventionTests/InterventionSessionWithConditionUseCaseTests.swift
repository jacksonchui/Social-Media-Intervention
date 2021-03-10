//
//  InterventionSessionWithConditionUseCaseTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/10/21.
//

import XCTest

class InterventionSessionWithConditionUseCaseTests: XCTestCase {
    
    func test_init_withConditionServiceAndUpdateInterval() {
        let (session, _) = makeSUT()
        
        XCTAssertNotNil(session.service)
        XCTAssertEqual(session.interval, 1.0)
    }
    
    func test_startSession_failsOnStartErrorOnFirstPeriod() {
        let (session, service) = makeSUT()
        let expectedError = ConditionPeriodError.startError
        
        let exp = expectation(description: "Wait for completion")
        
        session.start { error in
            XCTAssertEqual(error, expectedError)
            exp.fulfill()
        }
        
        service.completeStart(with: expectedError)
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    func makeSUT(updateInterval: TimeInterval = 1.0) -> (sut: InterventionSession, service: ConditionServiceSpy) {
        let service = ConditionServiceSpy()
        let session = InterventionSession(for: service, updatingEvery: updateInterval)
        
        return (session, service)
    }
    
    class ConditionServiceSpy: ConditionService {
        
        var startCompletions = [StartCompletion]()
        
        func check(completion: @escaping CheckCompletion) { }
        
        func start(completion: @escaping StartCompletion) {
            startCompletions.append(completion)
        }
        
        func stop(completion: @escaping StopCompletion) { }
        
        // MARK: - Completions
        
        func completeStart(with error: ConditionPeriodError, at index: Int = 0) {
            startCompletions[index](.failure(error))
        }
    }
}
