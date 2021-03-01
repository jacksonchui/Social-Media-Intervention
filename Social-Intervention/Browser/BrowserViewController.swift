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
    private(set) var conditionService = RotationConditionService()
    
    override func loadView() {
        super.loadView()
        browserView = WKWebView(frame: .zero)
        browserView.uiDelegate = self
        conditionService.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubviews(browserView)
        
        browserView.load(socialMedium.urlRequest)
        layoutUI()
        setAlpha(progress: 0.2)
        conditionService.start(completion: { _ in print("error with coremotion")})
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        conditionService.stop()
    }
    
    init(for socialMedium: SocialMedium = .twitter, use conditionService: RotationConditionService) {
        super.init(nibName: nil, bundle: nil)
        self.socialMedium = socialMedium
        self.conditionService = conditionService
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
    
    func setAlpha(progress: Double) {
        let newAlpha = progress > 0.5 ? 1 : CGFloat(abs(progress + 0.1))
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.3) {
                self.view.alpha = newAlpha
            }
            
            print("[DEBUG] Alpha:\(self.browserView.alpha).")
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
                    rootViewController: BrowserViewController(
                                        for: .twitter,
                                        use: RotationConditionService(withUpdateInterval: 1)))
        }
        
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    }
}
