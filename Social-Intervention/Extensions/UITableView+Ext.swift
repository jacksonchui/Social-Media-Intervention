//
//  UITableView+Ext.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/21/21.
//

import UIKit

internal extension UITableView {
    func removeExcessCells() {
        tableFooterView = UIView(frame: .zero)
    }
}
