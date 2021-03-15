//
//  ConditionSessionPolicy.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/15/21.
//

import Foundation
import CoreGraphics

internal final class ConditionSessionPolicy {
    static func toAlpha(_ progress: Double) -> CGFloat {
        return CGFloat(progress)
    }
}
