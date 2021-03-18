//
//  ConditionSessionPolicy.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/15/21.
//

import Foundation

internal final class ConditionSessionPolicy {
    private init() {}
    
    static var unmetThresholdFactor: Double { return 0.3 }
    
    static func toAlphaLevel(_ progress: Double) -> Double {
        print("Progress: \(progress)")
        let alphaLevel = applyFactorIfProgressDoesntMeetThreshold(to: progress)
        return alphaLevel
    }
    
    private static func applyFactorIfProgressDoesntMeetThreshold(to progress: Double) -> Double {
        let alphaLevel = progress < SessionPolicy.intervalCompleteThreshold ? unmetThresholdFactor * progress : progress
        return alphaLevel.truncate(places: 2)
    }
}
