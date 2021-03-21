//
//  SocialMedium.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 2/28/21.
//

import Foundation

public enum SocialMedium: String, CaseIterable {
    case facebook = "https://m.facebook.com/"
    case twitter = "https://mobile.twitter.com/"
    case instagram = "https://www.instagram.com/"
    case tiktok = "https://www.tiktok.com/"
    case reddit = "https://www.reddit.com/"
    case youtube = "https://m.youtube.com/"
    case linkedIn = "https://www.linkedin.com/"
    
    public var url: URL { URL(string: self.rawValue)! }
    public var urlRequest: URLRequest { URLRequest(url: self.url) }
}
