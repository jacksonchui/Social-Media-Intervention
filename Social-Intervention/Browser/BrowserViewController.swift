//
//  BrowserViewController.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 2/28/21.
//

import WebKit
import SafariServices

internal class BrowserViewController: UIViewController, WKUIDelegate {
    
    private(set) var socialMedium: SocialMedium!
    private(set) var browserView: WKWebView!
    private(set) var sessionManager: SessionManager!
    private var presentedSafariView: Bool = false
    private var switchSocialMedium: Bool = false
    
    override func loadView() {
        super.loadView()
        browserView = WKWebView(frame: .zero)
        browserView.uiDelegate = self
        browserView.navigationDelegate = self
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
        setupSocialSelector()
        sessionManager.start(loggingTo: nil, completion: onEachSessionUpdate)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !presentedSafariView {
            sessionManager.stop { }
        }
        presentedSafariView = false
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
            browserView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            browserView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            browserView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        )
        view.backgroundColor = .white
                
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
    
    private func changeAlpha(to newAlphaLevel: Double, animateWithDuration: TimeInterval = 0.3) {
        UIView.animate(withDuration: animateWithDuration) {
            self.view.alpha = CGFloat(newAlphaLevel)
            //print("[DEBUG] Alpha:\(self.view.alpha).")
        }
    }
}

extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        print(url.absoluteString)
        
        guard url.absoluteString.starts(with: socialMedium.rawValue) else {
            tryPresentSafariModalForNonSocialMediumURL(for: url)
            decisionHandler(.cancel)
            return
        }
        print("Swapped to social medium \(socialMedium.rawValue)")
        switchSocialMedium = false
        decisionHandler(.allow)
    }
    
    private func tryPresentSafariModalForNonSocialMediumURL(for url: URL) {
        guard isValidURL(url) && !isBadURL(url) else {
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        presentedSafariView = true
        self.present(safariVC, animated: true)
    }
    
    private func isValidURL(_ url: URL) -> Bool {
        let startsWithHTTP = url.absoluteString.starts(with: "http://")
        let startsWithHTTPS = url.absoluteString.starts(with: "https://")
        return startsWithHTTP || startsWithHTTPS
    }
    
    private func isBadURL(_ url: URL) -> Bool {
        let badURLs: [String] = [ "radar.cedexis.com", "https://www.redditmedia.com/gtm/jail?id", "accounts.google.com" ]
        for badURL in badURLs {
            if url.absoluteString.contains(badURL) {
                return true
            }
        }
        return false
    }
}

extension BrowserViewController: UIPopoverPresentationControllerDelegate, SocialPopoverControllerDelegate {
    func socialPopover(controller: SocialPopoverController, didSelectItem socialMedium: SocialMedium) {
        self.socialMedium = socialMedium
        self.switchSocialMedium = true
        
        DispatchQueue.main.async {
            self.browserView.load(socialMedium.urlRequest)
        }
    }
    
    private func setupSocialSelector() {
        let socialMediumSelect = UIBarButtonItem(title: "Change", style: .plain, target: self, action: #selector(showMenu))
        navigationItem.rightBarButtonItems = [socialMediumSelect]
    }
    
    @objc private func showMenu(sender: UIBarButtonItem) {
        // configure the presentation view controller
        let popoverController = SocialPopoverController()
        popoverController.delegate = self
        popoverController.modalPresentationStyle = .popover
        let popoverConfig = popoverController.popoverPresentationController
        
        popoverConfig?.delegate = self
        popoverConfig?.permittedArrowDirections = .up
        popoverConfig?.barButtonItem = sender
        
        present(popoverController, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
     
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
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
