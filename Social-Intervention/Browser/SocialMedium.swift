//
//  SocialMedium.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 2/28/21.
//

import Foundation

public enum SocialMedium: String {
    case facebook = "https://facebook.com/"
    case twitter = "https://twitter.com/"
    case instagram = "https://instagram.com/"
    
    public var url: URL { URL(string: self.rawValue)! }
    public var urlRequest: URLRequest { URLRequest(url: self.url) }
}
