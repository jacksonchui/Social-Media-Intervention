//
//  BrowserViewController.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 2/28/21.
//

import WebKit
import SafariServices

internal class BrowserViewController: UIViewController {
    
    private(set) var socialMedium: SocialMedium!
    private(set) var browserView: WKWebView!
    private(set) var sessionManager: SessionManager!
    private var presentedSafariView: Bool = false
    private var switchSocialMedium: Bool = false
    
    override func loadView() {
        super.loadView()
        browserView = WKWebView(frame: .zero)
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
        setupRightBarButtonItems()
        setupBrowserNavigationButtons()
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
            browserView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(BrowserToolbar.toolbarHeight + 34)),
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
    
    @objc private func endSession() {
        sessionManager.stop {}
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
            self.navigationController?.view.alpha = CGFloat(newAlphaLevel)
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
        
        guard isCurrentSocial(url) else {
            presentSafariVCForNonSocialURL(for: url)
            decisionHandler(.cancel)
            return
        }
        print("Swapped to \(socialMedium.title)")
        decisionHandler(.allow)
    }
    
    private func presentSafariVCForNonSocialURL(for url: URL) {
        guard url.isValidURL() && !url.isBadURL() else {
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        presentedSafariView = true
        self.present(safariVC, animated: true)
    }
    
    private func isCurrentSocial(_ url: URL) -> Bool {
        return url.absoluteString.starts(with: socialMedium.rawValue)
    }
}

extension BrowserViewController: UIPopoverPresentationControllerDelegate, SocialPopoverControllerDelegate {
    func socialPopover(controller: SocialPopoverController, didSelect socialMedium: SocialMedium) {
        self.socialMedium = socialMedium
        
        DispatchQueue.main.async {
            self.browserView.load(socialMedium.urlRequest)
            self.navigationItem.leftBarButtonItem?.title = socialMedium.title
        }
    }
    
    private func setupSocialSelector() {
        let socialSelectButton = UIBarButtonItem(title: socialMedium.title, style: .plain, target: self, action: #selector(showMenu))
        navigationItem.leftBarButtonItem = socialSelectButton
    }
    
    private func setupRightBarButtonItems() {
        let endSessionButton = UIBarButtonItem(title: "End Session", style: .plain, target: self, action: #selector(endSession))
        navigationItem.rightBarButtonItems = [endSessionButton]
    }
    
    private func setupBrowserNavigationButtons() {
        let backImage = UIImage(systemName: "chevron.backward")
        let forwardImage = UIImage(systemName: "chevron.forward")
        let back = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(goBack))
        let forward = UIBarButtonItem(image: forwardImage, style: .plain, target: self, action: #selector(goForward))
        
        toolbarItems = [back, forward]
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    @objc private func goBack(_ sender: Any) {
        browserView.goBack()
    }
    
    @objc private func goForward(_ sender: Any) {
        browserView.goForward()
    }
    
    @objc private func showMenu(sender: UIBarButtonItem) {

        let popoverController = SocialPopoverController(for: self)
        popoverController.modalPresentationStyle = .popover
        let popoverConfig = popoverController.popoverPresentationController
        
        popoverConfig?.delegate = self
        popoverConfig?.barButtonItem = sender
        
        present(popoverController, animated: true)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
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
