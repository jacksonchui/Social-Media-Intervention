//
//  BrowserViewControllerTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 2/28/21.
//

import XCTest

enum SocialMedium: String {
    case facebook = "https://facebook.com"
    case twitter = "https://twitter.com"
    case instagram = "https://instagram.com"
    
    var url: URL { URL(string: self.rawValue)! }
}

class BrowserViewController: UIViewController {
    
    public var socialMedium: SocialMedium?
    
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
        let sut = BrowserViewController()
        
        XCTAssertEqual(sut.socialMedium, SocialMedium.twitter)
    }
    
    func test_init_socialMediumPropertyIsSet() {
        let socials: [SocialMedium] = [.facebook, .twitter, .instagram]
        
        socials.forEach{ medium in
            let sut = BrowserViewController(use: medium)
            XCTAssertEqual(sut.socialMedium, medium)
        }
    }
}
