//
//  BrowserToolbar.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/21/21.
//

import UIKit

class BrowserToolbar: UIToolbar {
    static let toolbarHeight: CGFloat = 42
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.height = BrowserToolbar.toolbarHeight
        return size
    }
}
