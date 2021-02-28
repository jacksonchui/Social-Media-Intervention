//
//  BrowserViewControllerTests.swift
//  Social-InterventionTests
//
//  Created by Jackson Chui on 2/28/21.
//

import XCTest

class BrowserViewControllerTests: XCTestCase {
    
    func test_init_noSocialMediumDefaultsToTwitter() {
        XCTAssertEqual(makeSUT().socialMedium, SocialMedium.twitter)
    }
    
    func test_init_socialMediumPropertyIsSet() {
        forEachSocialMedium { [weak self] medium in
            guard let self = self else {
                XCTFail()
                return
            }
            XCTAssertEqual(self.makeSUT(use: medium).socialMedium, medium)
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
    
    func test_viewDidLoad_startsAPeriodicTimerForUpdates() {
        let sut = self.makeSUT(use: .twitter)
        sut.expectAfterViewDidLoad(url: SocialMedium.twitter.url)
        
        sut.startTimer()
        
        XCTAssertNotNil(sut.timer)
        
        sut.stopTimer()
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
