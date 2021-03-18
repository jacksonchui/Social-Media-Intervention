//
//  SessionPolicy.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/10/21.
//

import Foundation
import CoreGraphics

internal final class SessionPolicy {
    private init() { }
    
    static var periodDuration: TimeInterval { return 60.0 }
    static var periodCompletedRatio: Double { return 0.7 }
    static var intervalCompleteThreshold: Double { return 0.8 }
    static var updateDuration: TimeInterval { return 0.25 }
}
