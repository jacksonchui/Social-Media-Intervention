//
//  FirestoreAnalyticsClient.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/18/21.
//

import XCTest

import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreAnalyticsClientTests: XCTestCase {
    func test_save_analyticsDoesNotFailIfNoError() {
        let sessionAnalytics = uniqueSessionLog(endTime: Date.init).model
        let sut = makeSUT()
        
        let exp = expectation(description: "save completion")
        
        sut.save(sessionAnalytics) { error in
            if let error = error {
                XCTFail("Expected no error on save session but got \(error.localizedDescription)")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: Helpers
    
    func makeSUT() -> FirestoreAnalyticsClient {
        let sut = FirestoreAnalyticsClient()
        sut.enableEmulationForTests()
        return sut
    }
    
    func uniqueSessionLog(duration: TimeInterval = 0, periodLogs: [PeriodLog] = [], endTime: () -> Date) -> (log: SessionLog, model: SessionModel) {
        let startTime = endTime() - duration
        let sessionLog = SessionLog(startTime: startTime, endTime: endTime(), periodLogs: periodLogs)
        return (sessionLog, sessionLog.analytics)
    }
}

private extension FirestoreAnalyticsClient {
    func enableEmulationForTests() {
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        store.settings = settings
    }
}
