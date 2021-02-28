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
    private(set) var timer: Timer?
    
    override func loadView() {
        super.loadView()
        browserView = WKWebView(frame: .zero)
        browserView.uiDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        browserView.load(socialMedium.urlRequest)
    }
    
    init(use socialMedium: SocialMedium = .twitter) {
        super.init(nibName: nil, bundle: nil)
        self.socialMedium = socialMedium
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            print(timer.timeInterval)
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
