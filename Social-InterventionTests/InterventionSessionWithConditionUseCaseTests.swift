//
//  InterventionSessionWithConditionUseCaseTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/10/21.
//

import XCTest

class InterventionSessionWithConditionUseCaseTests: XCTestCase {
    
    func test_init_withConditionServiceAndUpdateInterval() {
        let (sut, _) = makeSUT()
        
        XCTAssertNotNil(sut.service)
        XCTAssertEqual(sut.interval, 1.0)
    }
    
    func test_startSession_failsOnStartErrorOnFirstPeriod() {
        let (sut, service) = makeSUT()
        let expectedError = ConditionPeriodError.startError
        
        expectOnStart(sut, toCompleteWith: .failure(error: expectedError)) {
            service.completeStart(with: expectedError)
        }
    }
    
    func test_startSession_startsFirstPeriodWithProgressFromServiceSuccessfully() {
        let (sut, service) = makeSUT()
        
        expectOnStart(sut, toCompleteWith: .success(progress: anyProgress())) {
            service.completeStartSuccessfully(with: anyProgress())
        }
    }
    
    // MARK: - Helpers
    
    func makeSUT(updateInterval: TimeInterval = 1.0) -> (sut: InterventionSession, service: ConditionServiceSpy) {
        let service = ConditionServiceSpy()
        let session = InterventionSession(for: service, updatingEvery: updateInterval)
        
        return (session, service)
    }
    
    func expectOnStart(_ sut: InterventionSession, toCompleteWith expectedResult: InterventionSession.StartResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        
        sut.start { result in
            XCTAssertEqual(expectedResult, result, file: file, line: line)
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
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
        
        func completeStartSuccessfully(with progress: Double, at index: Int = 0) {
            startCompletions[index](.success(latestMotionProgress: progress))
        }
    }
    
    private func anyProgress() -> Double {
        return 0.5
    }
}
