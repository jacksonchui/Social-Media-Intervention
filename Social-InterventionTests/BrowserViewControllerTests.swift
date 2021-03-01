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
    
    func test_afterViewDidLoad_startThenStop_togglesTheUpdateService() {
        let sut = self.makeSUT(use: .twitter)
        sut.expectAfterViewDidLoad(url: SocialMedium.twitter.url)
        
        XCTAssertNotNil(sut.updateService.timer)
        sut.viewDidDisappear(true)
        XCTAssertNil(sut.updateService.timer)
    }
    
    // MARK: Helpers
    
    func makeSUT(use socialMedium: SocialMedium = .twitter, withUpdateInterval: TimeInterval = 1, repeats: Bool = true) -> BrowserViewController {
        return BrowserViewController(use: socialMedium, withUpdateInterval: withUpdateInterval, repeats: repeats)
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
        XCTAssert(view.subviews.contains(browserView))
        XCTAssertEqual(browserView.url!, url)
    }
}
