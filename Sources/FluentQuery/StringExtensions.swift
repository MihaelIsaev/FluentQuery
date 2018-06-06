//
//  StringExtensions.swift
//  App
//
//  Created by Mihael Isaev on 06.06.2018.
//

import Foundation

extension String {
    var singleQuotted: String {
        return "'\(self)'"
    }
    
    var doubleQuotted: String {
        return "\"\(self)\""
    }
    
    var roundBracketted: String {
        return "(\(self))"
    }
}
