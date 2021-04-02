//
//  FirestoreAnalyticsClient.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/18/21.
//

import XCTest

import FirebaseFirestore
import FirebaseFirestoreSwift

typealias AnalyticsSaveError = Error?

class FirestoreAnalyticsClient {
    private let store: Firestore
    private let path: String = "sessions"
    
    init() {
        store = Firestore.firestore()
    }
    
    func save(_ sessionLog: SessionLog, completion: (AnalyticsSaveError) -> Void) {
        do {
            _ = try store.collection(path).addDocument(from: sessionLog)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

class FirestoreAnalyticsClientTests: XCTestCase {
    func test_save_sessionLog_doesNotFailIfNoError() {
        let sessionLog = uniqueSessionLog(endTime: Date.init)
        let sut = makeSUT()
        
        let exp = expectation(description: "save completion")
        
        sut.save(sessionLog) { error in
            if let error = error {
                XCTFail("Expected no error on save session but got \(error.localizedDescription)")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: Helpers
    
    func makeSUT() -> FirestoreAnalyticsClient {
        FirestoreAnalyticsClient()
    }
    
    func uniqueSessionLog(duration: TimeInterval = 0, periodLogs: [PeriodLog] = [], endTime: () -> Date) -> SessionLog {
        let startTime = endTime() - duration
        let sessionLog = SessionLog(startTime: startTime, endTime: endTime(), periodLogs: periodLogs)
        return sessionLog
    }
}

private extension FirestoreAnalyticsClient {
    func enableEmulationForTests() {
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
    }
}
