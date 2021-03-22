//
//  SocialPopoverController.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/21/21.
//

import Foundation
import UIKit

protocol SocialPopoverControllerDelegate: class {
    func socialPopover(controller: SocialPopoverController, didSelect socialMedium: SocialMedium)
}

class SocialPopoverController: UIViewController {
    
    static let reuseID = "SocialSelectCell"
    
    private(set) var tableView: UITableView?
    private(set) var delegate: SocialPopoverControllerDelegate?
    
    init(for delegate: SocialPopoverControllerDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        configureController()
    }
    
    private func configureController() {
        popoverPresentationController?.permittedArrowDirections = .up
    }
    
    private func setupTableView() {
        tableView = PopoverTableView(frame: view.frame, isScrollable: false, rowHeight: 44)
        
        if let tableView = tableView {
            view.addSubview(tableView)
            tableView.delegate = self
            tableView.dataSource = self
        }
                
        if let rowHeight = tableView?.rowHeight {
            let popOverHeight = SocialMedium.allCases.count * Int(rowHeight)
            preferredContentSize = CGSize(width: 150, height: popOverHeight)
        }
    }
}

extension SocialPopoverController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SocialMedium.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeCell()
        cell.textLabel?.text = SocialMedium.allCases[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let social = SocialMedium.allCases[indexPath.row]
        self.delegate?.socialPopover(controller: self, didSelect: social)
        self.dismissThisView()
    }
    
    // MARK: - Helpers
    
    private func dequeCell() -> UITableViewCell {
        let reuseID = SocialPopoverController.reuseID
        guard let cell = tableView!.dequeueReusableCell(withIdentifier: reuseID) else {
            let defaultCell = UITableViewCell(style: .default, reuseIdentifier: reuseID)
            return defaultCell
        }
        return cell
    }
}
