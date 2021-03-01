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
        view.addSubview(browserView)
        
        browserView.load(socialMedium.urlRequest)
        layoutUI()
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
    
    func layoutUI() {
        activateNSLayoutConstraints(
            browserView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            browserView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            browserView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            browserView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        )
        browserView.translatesAutoresizingMaskIntoConstraints = false
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
            return UINavigationController(rootViewController: BrowserViewController(withUpdateInterval: 2, repeats: true))
        }
        
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    }
}
