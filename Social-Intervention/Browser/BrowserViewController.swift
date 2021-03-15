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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubviews(browserView)
        
        browserView.load(socialMedium.urlRequest)
        layoutUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // to stop
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
    
    func setAlpha(progress: Double, animateWithDuration: TimeInterval = 0.3) {
        let newAlpha: CGFloat = CGFloat(abs(progress) > 0.9 ? 1 : abs(progress + 0.1))
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: animateWithDuration, animations: {
                self.view.alpha = newAlpha
            }) { _ in
                print("[DEBUG] Alpha:\(self.view.alpha).")
            }
        }
    }
}

extension BrowserViewController: ConditionServiceDelegate {
    func condition(progress: Double) {
        setAlpha(progress: progress)
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
