//
//  InterventionPolicy.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/10/21.
//

import Foundation
import CoreGraphics

internal final class InterventionPolicy {
    private init() { }
    
    static func toAlpha(_ progress: Double) -> CGFloat {
        return CGFloat(progress)
    }
    
    static var endPeriodAlpha: CGFloat { return 1.0 }
    static var periodDuration: Double { return 120.0 }
    static var resetStateThreshold: Double { return 0.7 }
    static var timeInterval: TimeInterval { return 1.0 }
}
