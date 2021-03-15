//
//  AlphaInterventionSessionTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/10/21.
//

import XCTest

struct SessionLogEntry: Equatable {
    var progressOverPeriod: [Double]
    var periodDuration: TimeInterval
}

class AlphaInterventionSession {
    
    public typealias CheckError = MotionAvailabilityError
    public typealias CheckCompletion = (CheckError?) -> Void
    
    public enum StartResult: Equatable {
        case success(alpha: CGFloat)
        case failure(error: ConditionPeriodError)
    }
    public typealias StartCompletion = (StartResult) -> Void
    
    public typealias StopError = ConditionPeriodError?
    public typealias StopCompletion = (StopError) -> Void
    
    private(set) var service: ConditionServiceSpy
    private(set) var analytics: SIAnalyticsController
    private(set) var sessionLog = [SessionLogEntry]()
    private(set) var progressOverPeriod = [Double]()
    private(set) var periodCount: Int
    
    init(using service: ConditionServiceSpy, sendsLogTo analytics: SIAnalyticsController) {
        self.service = service
        self.analytics = analytics
        self.periodCount = 1
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
    
    public func stop(completion: @escaping StopCompletion) {
        service.stop { result in
            switch result {
                case let .failure(error):
                    completion(error)
                default:
                    break
            }
        }
        analytics.save(sessionLog)
    }
    
    private func decideNextPeriod() {
        progressOverPeriod.append(service.progressAboveThreshold)
        
        if progressOverPeriod.last! >= InterventionPolicy.periodCompletedRatio {
            let entry = SessionLogEntry(
                            progressOverPeriod: progressOverPeriod,
                            periodDuration: service.currentPeriodTime)
            sessionLog.append(entry)
            service.reset()
            resetPeriod()
        } else {
            periodCount += 1
            service.continuePeriod()
        }
    }
    
    private func resetPeriod() {
        periodCount = 1
        progressOverPeriod = []
    }
}

class ConditionServiceSpy: ConditionService {
    var currentPeriodTime: TimeInterval
    var progressAboveThreshold: Double
    
    var checkCompletions = [CheckCompletion]()
    var startCompletions = [StartCompletion]()
    var stopCompletions = [StopCompletion]()
    
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
    
    func stop(completion: @escaping StopCompletion) {
        stopCompletions.append(completion)
    }
    
    func reset() {
        currentPeriodTime = 0
        progressAboveThreshold = 0
    }
    
    func continuePeriod() {
        progressAboveThreshold = 0
    }
    
    func completeCheck(with error: AlphaInterventionSession.CheckError?, at index: Int = 0) {
        checkCompletions[index](error)
    }
    
    func completeStartSuccessfully(with progress: Double, at index: Int = 0) {
        currentPeriodTime += 1
        startCompletions[index](.success(latestMotionProgress: progress))
    }
    
    func completeStopSuccessfully(at index: Int = 0) {
        stopCompletions[index](.success(progressAboveThreshold: anyProgress()))
    }
}

class SIAnalyticsController {
    public func save(_ log: [SessionLogEntry]) {
        
    }
}

class AlphaInterventionSessionTests: XCTestCase {
    func test_init_setsConditionServiceAndResetsPeriodCount() {
        let (sut, _, _ ) = makeSUT()
        
        XCTAssertNotNil(sut.service)
        XCTAssertEqual(sut.periodCount, 1)
    }
    
    func test_check_deliverErrorOnDeviceMotionUnavailable() {
        let (sut, service, _) = makeSUT()
        let expectedError: AlphaInterventionSession.CheckError = .deviceMotionUnavailable
        
        expectOnCheck(sut, toCompleteWith: expectedError) {
            service.completeCheck(with: expectedError)
        }
    }
    
    func test_check_deliverErrorOnReferenceFrameUnavailable() {
        let (sut, service, _) = makeSUT()
        let expectedError: AlphaInterventionSession.CheckError = .attitudeReferenceFrameUnavailable
        
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
    
    func makeSUT() -> (sut: AlphaInterventionSession, service: ConditionServiceSpy, analytics: SIAnalyticsController) {
        let service = ConditionServiceSpy()
        let analytics = SIAnalyticsController()
        let session = AlphaInterventionSession(using: service, sendsLogTo: analytics)
        
        return (session, service, analytics)
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
    
    func expectOnStart(_ sut: AlphaInterventionSession, toCompleteWith expectedError: ConditionPeriodError?, for expectedUpdatesCount: Int, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
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
