//
//  BrowserViewControllerTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 2/28/21.
//

import XCTest
import WebKit

enum SocialMedium: String {
    case facebook = "https://facebook.com/"
    case twitter = "https://twitter.com/"
    case instagram = "https://instagram.com/"
    
    var url: URL { URL(string: self.rawValue)! }
    var urlRequest: URLRequest { URLRequest(url: self.url) }
}

class BrowserViewController: UIViewController, WKUIDelegate {
    
    private var socialMedium: SocialMedium!
    private var browserView: WKWebView!
    
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
}

class BrowserViewControllerTests: XCTestCase {
    
    func test_init_noSocialMediumDefaultsToTwitter() {
        XCTAssertEqual(makeSUT().getSocialMedium(), SocialMedium.twitter)
    }
    
    func test_init_socialMediumPropertyIsSet() {
        forEachSocialMedium { [weak self] medium in
            guard let self = self else {
                XCTFail()
                return
            }
            XCTAssertEqual(self.makeSUT(use: medium).getSocialMedium(), medium)
        }
    }
    
    func test_loadView_then_viewDidLoad_loadsSocialMediumIntoBrowserView() {
        forEachSocialMedium { [weak self] medium in
            guard let self = self else {
                XCTFail()
                return
            }
            self.makeSUT(use: medium).expectAfterViewDidLoad(url: medium.url)
        }
    }
    
    // MARK: Helpers
    
    func makeSUT(use socialMedium: SocialMedium = .twitter) -> BrowserViewController {
        return BrowserViewController(use: socialMedium)
    }
    
    func forEachSocialMedium(completion: @escaping (SocialMedium) -> Void) {
        let socials: [SocialMedium] = [.facebook, .twitter, .instagram]
        socials.forEach{ completion($0) }
    }
}

private extension BrowserViewController {
    
    func getSocialMedium() -> SocialMedium {
        return socialMedium
    }
    
    func expectDidLoadView(filePath: StaticString = #filePath, line: UInt = #line) {
        loadView()
        XCTAssertNoThrow(browserView)
        XCTAssertNotNil(browserView.uiDelegate)
    }
    
    func expectAfterViewDidLoad(url: URL, filePath: StaticString = #filePath, line: UInt = #line) {
        expectDidLoadView()
        viewDidLoad()
        XCTAssertEqual(browserView.url!, url)
    }
}
