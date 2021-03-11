////
////  InterventionSessionWithConditionUseCaseTests.swift
////  Social-InterventionTests
////
////  Created by Jackson Chui on 3/10/21.
////
//
//import XCTest
//
//class InterventionSessionWithConditionUseCaseTests: XCTestCase {
//    
////    func test_init_withConditionServiceAndUpdateInterval() {
////        let (sut, _) = makeSUT()
////
////        XCTAssertNotNil(sut.service)
////        XCTAssertEqual(sut.interval, 1.0)
////    }
//    
//    func test_checkAvailability_failsOnDeviceMotionError() {
//        let (sut, service) = makeSUT()
//        let expectedError = InterventionSession.CheckError.deviceMotionUnavailable
//        
//        expectOnCheck(sut, toCompleteWith: expectedError) {
//            service.completeCheck(with: expectedError)
//        }
//    }
//    
//    func test_checkAvailability_failsOnAttitudeReferenceFrameError() {
//        let (sut, service) = makeSUT()
//        let expectedError = InterventionSession.CheckError.attitudeReferenceFrameUnavailable
//        
//        expectOnCheck(sut, toCompleteWith: expectedError) {
//            service.completeCheck(with: expectedError)
//        }
//    }
//    
//    func test_startSession_failsOnStartErrorOnFirstPeriod() {
//        let (sut, service) = makeSUT()
//        let expectedError = ConditionPeriodError.startError
//        
//        expectOnStart(sut, toCompleteWith: expectedError) {
//            service.completeStart(with: expectedError)
//        }
//    }
//    
//    func test_startSession_deliversAlphaValueBasedOnProgressSuccessfully() {
//        let (sut, service) = makeSUT()
//        let expectedRecord = anyProgress()
//        
//        expectOnStart(sut, toCompleteWith: nil) {
//            service.completeStartSuccessfully(with: expectedRecord)
//        }
//    }
//    
//    func test_startSession_deliversMultipleAlphaValuesBasedOnProgressesSuccessfully() {
//        let (sut, service) = makeSUT()
//        let expectedRecords = anyProgresses()
//        
//        expectOnStart(sut, toCompleteWith: nil, forExpectedUpdates: expectedRecords.count) {
//            expectedRecords.forEach {
//                service.completeStartSuccessfully(with: $0)
//            }
//        }
//    }
//    
//    // MARK: - Helpers
//    
//    func makeSUT(updateInterval: TimeInterval = 1.0) -> (sut: InterventionSession, service: ConditionServiceSpy) {
//        let service = ConditionServiceSpy()
//        let session = InterventionSession(for: service)
//
//        return (session, service)
//    }
//    
//    func expectOnCheck(_ sut: InterventionSession, toCompleteWith expectedError: InterventionSession.CheckError, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
//        let exp = expectation(description: "Wait for completion")
//        
//        sut.check { error in
//            XCTAssertEqual(expectedError, error, file: file, line: line)
//            exp.fulfill()
//        }
//
//        action()
//        wait(for: [exp], timeout: 1.0)
//    }
//    
//    func expectOnStart(_ sut: InterventionSession, toCompleteWith expectedError: InterventionSession.StartError? = nil, forExpectedUpdates count: Int = 1, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
//        let exp = expectation(description: "Wait for completion")
//        exp.expectedFulfillmentCount = count
//        
//        sut.start { result in
//            switch result {
//                case let .success(alpha: alpha):
//                    XCTAssertGreaterThanOrEqual(alpha, 0.0, file: file, line: line)
//                    XCTAssertLessThanOrEqual(alpha, 1.0, file: file, line: line)
//                case let .failure(error: error):
//                    XCTAssertEqual(error, expectedError, file: file, line: line)
//            }
//            
//            exp.fulfill()
//        }
//
//        action()
//        wait(for: [exp], timeout: 1.0)
//    }
//    
//    class ConditionServiceSpy: ConditionService {
//        var currentPeriodTime: TimeInterval
//        
//        func resetState() {
//            <#code#>
//        }
//        
//        var checkCompletions = [CheckCompletion]()
//        var startCompletions = [StartCompletion]()
//        
//        func check(completion: @escaping CheckCompletion) {
//            checkCompletions.append(completion)
//        }
//        
//        func start(completion: @escaping StartCompletion) {
//            startCompletions.append(completion)
//        }
//        
//        func stop(completion: @escaping StopCompletion) { }
//        
//        // MARK: - Completions
//        
//        func completeCheck(with error: InterventionSession.CheckError, at index: Int = 0) {
//            checkCompletions[index](error)
//        }
//        
//        func completeStart(with error: ConditionPeriodError, at index: Int = 0) {
//            startCompletions[index](.failure(error))
//        }
//        
//        func completeStartSuccessfully(with progress: Double, at index: Int = 0) {
//            startCompletions[index](.success(latestMotionProgress: progress))
//        }
//    }
//}
