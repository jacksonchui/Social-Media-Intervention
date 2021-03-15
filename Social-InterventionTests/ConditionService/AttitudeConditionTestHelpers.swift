//
//  AttitudeConditionHelpers.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 3/10/21.
//

import Foundation

func anyAttitude() -> Attitude {
    return Attitude(roll: 0, pitch: 0, yaw: 0)
}

func anyAttitudes(_ count: Int = 10) -> [Attitude] {
    var attitudes = [Attitude]()
    for _ in 0..<count {
        attitudes.append(randomAttitude)
    }
    return attitudes
}

var randomRadian: Double {
    let sigFigures = 2
    return Double.random(in: -Double.pi/2...Double.pi/2).truncate(places: sigFigures)
}

var randomAttitude: Attitude { Attitude(roll: randomRadian, pitch: randomRadian, yaw: randomRadian) }
