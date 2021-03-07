//
//  RotationConditionServiceTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/1/21.
//

import XCTest

import CoreMotion

struct Motionable {}

enum MotionError: String, Swift.Error {
    case deviceMotionUnavailable = "Device Motion is unavailable"
    case attitudeReferenceFrameUnavailable = "Could not get the desired motion frame for device"
}

class AngleConditionService {
    
    private(set) var motionManager: MotionManagerSpy
    
    private(set) var timer: Timer?
    private var timeInterval: TimeInterval
    private var onEachInterval: ((Timer) -> Void)
    
    init(with motionManager: MotionManagerSpy, every timeInterval: TimeInterval, onEachInterval: @escaping (Timer) -> Void) {
        self.motionManager = motionManager
        self.onEachInterval = onEachInterval
        self.timeInterval = timeInterval
    }
    
    public func check(completion: @escaping (MotionError?) -> Void) {
        motionManager.checkAvailability(of: .xArbitraryZVertical, completion: completion)
        startTimer()
    }
    
    private func startTimer() {
        if timer != nil { stopTimer() }
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { timer in
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

class MotionManagerSpy {
    
    init(updateInterval: TimeInterval) { }
    
    typealias AvailabilityCompletion = (MotionError?) -> Void
    
    var availabilityCompletions = [AvailabilityCompletion]()
    
    func checkAvailability(of attitude: CMAttitudeReferenceFrame, completion: @escaping (MotionError?) -> Void) {
        availabilityCompletions.append(completion)
    }
    
    func complete(with error: MotionError, at index: Int = 0) {
        availabilityCompletions[index](error)
    }
    
    func completeWithNoCheckErrors(at index: Int = 0) {
        availabilityCompletions[index](nil)
    }
}

class AngleConditionServiceTests: XCTestCase {

    func test_init_setsUpMotionManagerAndQueue() {
        let (sut, _) = makeSUT {_ in }
        
        XCTAssertNotNil(sut.motionManager)
    }
    
    func test_start_failsWhenDeviceMotionUnavailable() {
        let (sut, motionManager) = makeSUT {_ in }
        let expectedError: MotionError = .deviceMotionUnavailable
                
        expect(sut, toCompleteWith: expectedError) {
            motionManager.complete(with: expectedError)
        }
    }
    
    func test_checkAvailability_failsWhenAttitudeReferenceFrameUnavailable() {
        let (sut, motionManager) = makeSUT {_ in }
        let expectedError: MotionError = .attitudeReferenceFrameUnavailable
        
        expect(sut, toCompleteWith: expectedError) {
            motionManager.complete(with: expectedError)
        }
    }
    
    func test_checkAvailability_nilifNoCheckErrors() {
        let (sut, motionManager) = makeSUT {_ in }
        
        expect(sut, toCompleteWith: nil) {
            motionManager.completeWithNoCheckErrors()
        }
    }
    

    
    // MARK: - Helpers
    func makeSUT(updateInterval: TimeInterval = 1.0, onEachInterval: @escaping (Timer) -> Void) -> (AngleConditionService, MotionManagerSpy) {
        let motionManager = MotionManagerSpy(updateInterval: updateInterval)
        let sut = AngleConditionService(with: motionManager, every: updateInterval, onEachInterval: onEachInterval)
        
        return (sut, motionManager)
    }
    
    func expect(_ sut: AngleConditionService, toCompleteWith expectedError: MotionError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for start completion")
        
        sut.check { error in
            if let error = error {
                XCTAssertEqual(error, expectedError)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
}
