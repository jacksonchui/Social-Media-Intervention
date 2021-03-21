//
//  SocialPopoverController.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/21/21.
//

import Foundation
import UIKit

protocol SocialPopoverControllerDelegate: class {
    func socialPopover(controller: SocialPopoverController, didSelectItem socialMedium: SocialMedium)
}

class SocialPopoverController: UIViewController {
    
    static let reuseID = "SocialSelectCell"
    
    var tableView: UITableView?
    var delegate:SocialPopoverControllerDelegate?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        setupTableView()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
     
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.frame)
        if let tableView = tableView {
            view.addSubview(tableView)
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
}

extension SocialPopoverController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SocialMedium.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeCell()
        cell.textLabel?.text = SocialMedium.allCases[indexPath.row].rawValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSocial = SocialMedium.allCases[indexPath.row]
        self.delegate?.socialPopover(controller: self, didSelectItem: selectedSocial)
        self.dismiss(animated: true, completion: nil)
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
