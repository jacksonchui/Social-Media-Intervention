//
//  InterventionSessionTestHelpers.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/10/21.
//

import CoreGraphics

var updatesPerPeriod: Int { return 120 }
var resetProgressThreshold: Double { return 0.7 }

func anyProgress() -> Double {
    return randomProgress
}

func anyProgresses(_ updateIntervals: Int = 100) -> [Double] {
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
