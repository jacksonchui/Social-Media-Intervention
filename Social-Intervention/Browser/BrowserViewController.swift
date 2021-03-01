//
//  BrowserViewController.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 2/28/21.
//

import WebKit

internal class BrowserViewController: UIViewController, WKUIDelegate {
    
    private(set) var socialMedium: SocialMedium!
    private(set) var browserView: WKWebView!
    private(set) var updateService: TimerIntervalUpdateService!
    
    override func loadView() {
        super.loadView()
        browserView = WKWebView(frame: .zero)
        browserView.uiDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        browserView.load(socialMedium.urlRequest)
        updateService.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateService.stop()
    }
    
    init(use socialMedium: SocialMedium = .twitter, withUpdateInterval: TimeInterval, repeats: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.socialMedium = socialMedium
        self.updateService = TimerIntervalUpdateService(withTimeInterval: 1, repeats: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
