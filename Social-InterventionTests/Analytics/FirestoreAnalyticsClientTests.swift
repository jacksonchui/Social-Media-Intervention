//
//  FirestoreAnalyticsClient.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/18/21.
//

import XCTest

import FirebaseFirestore
import FirebaseFirestoreSwift

internal extension SessionLog {
    var analytics: SessionModel {
        let duration = endTime?.timeIntervalSince(startTime) ?? 0
        return SessionModel(date: endTime, duration: duration, periods: periodLogs)
    }
}


public struct SessionModel: Codable {
    var date: Date?
    var duration: TimeInterval
    var periods: [PeriodLog]
}

typealias AnalyticsSaveError = Error?

class FirestoreAnalyticsClient {
    private let store: Firestore
    
    private var path: String {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        return "sessions_\(deviceID)"
    }
    
    init() {
        store = Firestore.firestore()
    }
    
    func save(_ session: SessionModel, completion: (AnalyticsSaveError) -> Void) {
        do {
            _ = try store.collection(path).addDocument(from: session)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

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
