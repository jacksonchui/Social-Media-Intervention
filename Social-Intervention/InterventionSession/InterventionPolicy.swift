//
//  InterventionPolicy.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/10/21.
//

import CoreGraphics

internal final class InterventionPolicy {
    private init() { }
    
    internal static func convertToAlpha(_ progress: Double) -> CGFloat {
        return CGFloat(progress)
    }
}
