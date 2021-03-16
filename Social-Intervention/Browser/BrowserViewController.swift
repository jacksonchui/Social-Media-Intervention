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
    private(set) var sessionManager: SessionManager!
    
    override func loadView() {
        super.loadView()
        browserView = WKWebView(frame: .zero)
        browserView.uiDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionManager.check(completion: onPossibleSessionCheckError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubviews(browserView)
        
        browserView.load(socialMedium.urlRequest)
        layoutUI()
        sessionManager.start(completion: onEachSessionUpdate)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        sessionManager.stop(completion: onSessionStop)
    }
    
    init(for socialMedium: SocialMedium = .twitter, managedBy sessionManager: SessionManager) {
        super.init(nibName: nil, bundle: nil)
        self.socialMedium = socialMedium
        self.sessionManager = sessionManager
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    func layoutUI() {
        activateNSLayoutConstraints(
            browserView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            browserView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            browserView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            browserView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        )
                
        browserView.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    func setViewAlpha(to level: Double, animateWithDuration: TimeInterval = 0.3) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.changeAlpha(to: level)
        }
    }
    
    private func onPossibleSessionCheckError(error: SessionCheckError?) {
        
    }
    
    private func onEachSessionUpdate(_ result: SessionStartResult) {
        switch result {
            case let .success(alphaLevel):
                setViewAlpha(to: alphaLevel)
            default:
                print("Will deal with error as an alert")
        }
    }
    
    private func onSessionStop(_ error: SessionStopError?) {
        if let error = error {
            print("Received error when trying to stop session: \(error.debugDescription)")
        }
    }
    
    private func changeAlpha(to newAlphaLevel: Double, animateWithDuration: TimeInterval = 0.3) {
        UIView.animate(withDuration: animateWithDuration) {
            self.view.alpha = CGFloat(newAlphaLevel)
            print("[DEBUG] Alpha:\(self.view.alpha).")
        }
    }
}


import SwiftUI
struct MainPreview: PreviewProvider {
    static var previews: some View {
        ContainerView()
            .edgesIgnoringSafeArea(.all)
        
    }
    
    struct ContainerView: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> UIViewController {
            return UINavigationController(
                    rootViewController: UIViewController())
        }
        
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    }
}
