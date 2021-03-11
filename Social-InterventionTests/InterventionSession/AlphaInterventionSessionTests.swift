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
    
    public enum StartResult: Equatable {
        case success(alpha: CGFloat)
        case failure(error: ConditionPeriodError)
    }
    public typealias StartCompletion = (StartResult) -> Void
    
    private(set) var service: ConditionServiceSpy
    private(set) var periodTimes = [TimeInterval]()
    private(set) var periodCount: Int
    
    init(using service: ConditionServiceSpy) {
        self.service = service
        periodCount = 1
    }
    
    public func check(completion: @escaping CheckCompletion) {
        service.check(completion: completion)
    }
    
    public func start(completion: @escaping StartCompletion) {
        service.start { [unowned self] result in
            switch result {
                case let .success(latestMotionProgress: progress):
                    completion(.success(alpha: InterventionPolicy.toAlpha(progress)))
                default:
                    break
            }
            
            if self.service.currentPeriodTime >= InterventionPolicy.periodDuration * Double(self.periodCount) {
                self.decideNextPeriod()
            }
        }
    }
    
    private func decideNextPeriod() {
        print("service.currentPeriodTime: \(service.currentPeriodTime)")
        if service.progressAboveThreshold >= InterventionPolicy.resetStateThreshold {
            periodTimes.append(service.currentPeriodTime)
            service.reset()
            resetPeriodCount()
        }
    }
    
    private func resetPeriodCount() { periodCount = 1 }
}

class ConditionServiceSpy: ConditionService {
    var currentPeriodTime: TimeInterval
    var progressAboveThreshold: Double
    
    var checkCompletions = [CheckCompletion]()
    var startCompletions = [StartCompletion]()
    
    init() {
        currentPeriodTime = 0
        progressAboveThreshold = 0
    }
    
    func check(completion: @escaping CheckCompletion) {
        checkCompletions.append(completion)
    }
    
    func start(completion: @escaping StartCompletion) {
        startCompletions.append(completion)
    }
    
    func stop(completion: @escaping StopCompletion) { }
    
    func reset() {
        currentPeriodTime = 0
        progressAboveThreshold = 0
    }
    
    func completeCheck(with error: AlphaInterventionSession.CheckError?, at index: Int = 0) {
        checkCompletions[index](error)
    }
    
    func completeStartSuccessfully(with progress: Double, at index: Int = 0) {
        currentPeriodTime += 1
        startCompletions[index](.success(latestMotionProgress: progress))
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

    func test_start_deliversAlphaOnEachUpdateForOnePeriodSuccessfully() {
        let (sut, service) = makeSUT()
        let expectedUpdates = anyProgresses(updatesPerPeriod)
        
        expectOnStart(sut, toCompleteWith: nil, for: expectedUpdates.count) {
            expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
        }
    }
    
    func test_start_resetsConditionServiceAndPeriodAndRecordsPeriodWhenAboveProgressThresholdOnTheLastUpdateForAPeriod() {
        let (sut, service) = makeSUT()
        let expectedUpdates = anyProgresses(updatesPerPeriod)
        service.progressAboveThreshold = resetProgressThreshold
        
        expectOnStart(sut, toCompleteWith: nil, for: expectedUpdates.count) {
            expectedUpdates.forEach { service.completeStartSuccessfully(with: $0) }
        }
        
        XCTAssertEqual(sut.periodCount, 1)
        XCTAssertEqual(service.currentPeriodTime, 0.0)
        XCTAssertEqual(sut.periodTimes, [Double(updatesPerPeriod)])
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
    
    func expectOnStart(_ sut: AlphaInterventionSession, toCompleteWith expectedError: ConditionPeriodError? = nil, for expectedUpdatesCount: Int = 1, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
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
