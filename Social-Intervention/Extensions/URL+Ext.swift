//
//  URL+Ext.swift
//  Social-Intervention
//
//  Created by Jackson Chui on 3/21/21.
//

import Foundation

internal extension URL {
    func isValidURL() -> Bool {
        let startsWithHTTP = self.absoluteString.starts(with: "http://")
        let startsWithHTTPS = self.absoluteString.starts(with: "https://")
        return startsWithHTTP || startsWithHTTPS
    }
    
    func isBadURL() -> Bool {
        let badURLs: [String] = [ "radar.cedexis.com", "https://www.redditmedia.com/gtm/jail?id", "accounts.google.com" ]
        for badURL in badURLs {
            if self.absoluteString.contains(badURL) {
                return true
            }
        }
        return false
    }
}
