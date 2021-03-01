//
//  UpdateServiceTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 2/28/21.
//

import XCTest

class TimerIntervalUpdateServiceTests: XCTestCase {

    func test_start_then_stop_createsAndDestroysTimer() {
        let sut = makeSUT()
        sut.start()
        XCTAssertNotNil(sut.timer)
        sut.stop()
        XCTAssertNil(sut.timer)
    }
    
    // MARK: Helpers
    
    private func makeSUT(withTimeInterval: TimeInterval = 1, repeats: Bool = true) -> TimerIntervalUpdateService {
        return TimerIntervalUpdateService(withTimeInterval: withTimeInterval, repeats: repeats)
    }
}
