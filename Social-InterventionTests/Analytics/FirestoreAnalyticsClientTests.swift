//
//  FirestoreAnalyticsClient.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/18/21.
//

import XCTest

import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreAnalyticsClient {
    let store: Firestore
    
    init() {
        store = Firestore.firestore()
    }
    
    func record(toServer sessionLog: SessionLog) {
        
    }
}

class FirestoreAnalyticsClientTests: XCTestCase {
    func test_sut_createsStore() {
        let sut = FirestoreAnalyticsClient()
        XCTAssertNotNil(sut.store, "Should create a Firestore instance")
    }
    
    func test_saveSession_createsNewSessionLogsOnFirstSave() {
        let sessionLog = SessionLog(startTime: Date() - 100, endTime: Date(), periodLogs: [])
        let sut = FirestoreAnalyticsClient()
        
        sut.record(toServer: sessionLog)
        
        // want to make sure that I can get data from the server as expected.
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
