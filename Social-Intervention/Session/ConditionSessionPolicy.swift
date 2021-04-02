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
    static var progressTolerance: Double { return 0.03 }
    
    static func toAlphaLevel(_ progress: Double, from currLevel: Double) -> Double {
        //print("Progress: \(progress)")
        let alphaLevel = applyFactorIfProgressDoesntMeetThreshold(to: progress, from: currLevel)
        return alphaLevel
    }
    
    private static func applyFactorIfProgressDoesntMeetThreshold(to progress: Double, from currLevel: Double) -> Double {
        let willChange = currLevel >= SessionPolicy.intervalCompleteThreshold - progressTolerance
        let nextFactor = willChange ? unmetThresholdFactor : 1.0
        let nextAlphaLevel = nextFactor * progress
        return nextAlphaLevel.truncate(places: 2)
    }
}
