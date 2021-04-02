//
//  FirestoreAnalyticsClient.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 4/1/21.
//

import Foundation

import FirebaseFirestore
import FirebaseFirestoreSwift
import UIKit

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

public typealias AnalyticsSaveError = Error?

public class FirestoreAnalyticsClient {
    public let store: Firestore
    
    private var path: String {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        return "sessions_\(deviceID)"
    }
    
    public init() {
        store = Firestore.firestore()
    }
    
    public func save(_ session: SessionModel, completion: (AnalyticsSaveError) -> Void) {
        do {
            print("Logging session model to \(store.settings.host) at document: \(path)")
            _ = try store.collection(path).addDocument(from: session)
            completion(nil)
        } catch {
            print("Unable to save session: \(error.localizedDescription)")
            completion(error)
        }
    }
}
