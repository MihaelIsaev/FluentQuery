//
//  StringExtensions.swift
//  App
//
//  Created by Mihael Isaev on 06.06.2018.
//

import Foundation

extension String {
    var singleQuotted: String {
        return "'" + self + "'"
    }
    
    var doubleQuotted: String {
        return "\"" + self + "\""
    }
    
    var roundBracketted: String {
        return "(" + self + ")"
    }
    
    static func singleQuotted(_ v: Any) -> String {
        return String(describing: v).singleQuotted
    }
    
    static func doubleQuotted(_ v: Any) -> String {
        return String(describing: v).doubleQuotted
    }
    
    static func roundBracketted(_ v: Any) -> String {
        return String(describing: v).roundBracketted
    }
    
    func `as`(_ v: String) -> String {
        return self + " as " + v
    }
}
