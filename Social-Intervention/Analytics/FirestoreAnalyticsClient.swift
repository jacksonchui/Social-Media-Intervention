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

public typealias Seconds = Int

public struct SessionModel: Codable {
    var date: Date
    var durationInSeconds: Seconds
    var periods: [PeriodLog]
    var socialMediaVisited: [String]
    
    var isValid: Bool {
        return self.durationInSeconds > 0 &&
                !self.socialMediaVisited.isEmpty &&
                !self.periods.isEmpty
    }
}

internal extension SessionLog {
    var model: SessionModel {
        let duration = endTime.timeIntervalSince(startTime).toSeconds
        return SessionModel(date: endTime, durationInSeconds: duration, periods: periodLogs, socialMediaVisited: [])
    }
    
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
        guard session.isValid else {
                print("[LOG] This is an invalid/empty Session analytics model. It will not be saved")
                completion(nil)
                return
        }
        
        do {
            print("[LOG] Saved session via Firestore to \(store.settings.host) in document: \(path)")
            print("[LOG] - Date: \(session.date.description)")
            print("[LOG] - Social Media Visited: \(session.socialMediaVisited)")
            print("[LOG] - Duration (sec): \(session.durationInSeconds)")
            print("[LOG] - Periods Completed: \(session.periods.count)")
            _ = try store.collection(path).addDocument(from: session)
            completion(nil)
        } catch {
            print("[ERROR] Unable to save session: \(error.localizedDescription)")
            completion(error)
        }
    }
    
}
