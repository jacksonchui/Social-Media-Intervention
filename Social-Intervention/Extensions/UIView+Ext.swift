//
//  UIView+Ext.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 2/28/21.
//

import UIKit

extension UIView {
    convenience init(backgroundColor: UIColor) {
        self.init()
        self.backgroundColor = backgroundColor
    }
    
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }
    
    func activateNSLayoutConstraints(_ constraints: NSLayoutConstraint...) {
        NSLayoutConstraint.activate(constraints)
    }
    
    public func pinToEdges(of parentView: UIView) {
        activateNSLayoutConstraints(
            self.topAnchor.constraint(equalTo: parentView.topAnchor),
            self.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            self.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            self.leadingAnchor.constraint(equalTo: parentView.leadingAnchor)
        )
    }
}
