//
//  UIViewController+Ext.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 2/28/21.
//

import UIKit

public extension UIViewController {
    func activateNSLayoutConstraints(_ constraints: NSLayoutConstraint...) {
        NSLayoutConstraint.activate(constraints)
    }
    
    func dismissThisView(_ animated: Bool = true) {
        self.dismiss(animated: animated, completion: nil)
    }
}
