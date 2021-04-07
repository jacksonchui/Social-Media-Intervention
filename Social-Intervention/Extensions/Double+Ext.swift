//
//  Double+Ext.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/15/21.
//

import Foundation

internal extension Double {
    func truncate(places : Int)-> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}

public extension TimeInterval {
    var toSeconds: Int {
        return Int(self.truncate(places: 0))
    }
}
