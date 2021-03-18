//
//  ConditionSessionManagerTestsHelpers.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/10/21.
//

import CoreGraphics
import Foundation

var periodCompletedRatio: Double { return 0.7 }
var periodDuration: TimeInterval { return 60.0 }
var updateDuration: TimeInterval { return 0.25 }
var updatesPerPeriodInterval: Int { return Int(periodDuration/updateDuration) }


func anyProgress() -> Double {
    return randomProgress
}

func anyProgresses(_ updateIntervals: Int = updatesPerPeriodInterval) -> [Double] {
    var progresses = [Double]()
    for _ in 0 ..< updateIntervals {
        progresses.append(randomProgress)
    }
    return progresses
}

private var randomProgress: Double {
    let sigFigures = 2
    return Double.random(in: 0...1).truncate(places: sigFigures)
}

func belowThreshold() -> Double {
    return periodCompletedRatio - 0.01
}

func atThreshold() -> Double {
    return periodCompletedRatio
}

func aboveThreshold() -> Double {
    return periodCompletedRatio + 0.01
}
    
func use(_ updatesPerInterval: Int = updatesPerPeriodInterval, intervals: Int)
        -> (progressUpdates: [Double], periodDuration: Double, totalPeriodUpdates: Int) {
    let progressUpdates = anyProgresses(updatesPerInterval)
    let totalPeriodUpdates = updatesPerInterval * intervals
    var periodDuration = Double(totalPeriodUpdates) * updateDuration
    periodDuration = periodDuration.truncate(places: 2)

    return (progressUpdates, periodDuration, totalPeriodUpdates)
}

private extension Array where Array.Element == Double {
    func withAlphas() -> [CGFloat] {
        return self.map { $0.toAlpha() }
    }
}

private extension Double {
    func toAlpha() -> CGFloat {
        return CGFloat(self)
    }
}

private extension CGFloat {
    func toProgress() -> Double {
        return Double(self)
    }
}

func anyNSError(_ msg: String) -> NSError {
    NSError(domain: msg, code: 0)
}
