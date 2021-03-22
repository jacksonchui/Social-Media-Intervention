//
//  PopoverTableView.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/21/21.
//

import UIKit

class PopoverTableView: UITableView {
   
    init(frame: CGRect) {
        super.init(frame: frame, style: .plain)
    }
    
    convenience init(frame: CGRect, isScrollable: Bool, rowHeight: CGFloat) {
        self.init(frame: .zero)
        self.frame = frame
        alwaysBounceVertical = isScrollable
        self.rowHeight = rowHeight
        removeExcessCells()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
