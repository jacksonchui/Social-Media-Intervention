//
//  ConditionSessionPolicy.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/15/21.
//

import Foundation

internal final class ConditionSessionPolicy {
    private init() {}
    
    static var incompleteFactor: Double { return 0.3 }
    
    // tolerance factors
    static var intervalCompleteTolerance: Double { return 0.1 }
    static var reducedIncompleteFactor: Double { return incompleteFactor * 1.5 }
    static var intervalCompleteThresholdWithTolerance: Double { return SessionPolicy.intervalCompleteThreshold - intervalCompleteTolerance }
    
    static func toAlphaLevel(_ progress: Double, from prevProgress: Double) -> Double {
        let alphaLevel = applyIncompleteFactor(to: progress, from: prevProgress)
        return alphaLevel
    }
    
    private static func applyIncompleteFactor(to progress: Double, from prevLevel: Double) -> Double {
        var nextAlphaLevel = progress
        let betweenToleranceAndThreshold = prevLevel >= intervalCompleteThresholdWithTolerance && prevLevel < SessionPolicy.intervalCompleteThreshold
        let belowThreshold = prevLevel < intervalCompleteThresholdWithTolerance
        
        if betweenToleranceAndThreshold {
            nextAlphaLevel *= reducedIncompleteFactor
        } else if belowThreshold {
            nextAlphaLevel *= incompleteFactor
        }
        
        return nextAlphaLevel.truncate(places: 2)
    }
}
