//
//  FQSelect.swift
//  FluentQuery
//
//  Created by Mihael Isaev on 05.06.2018.
//

import Foundation
import Fluent

public class FQSelect: FQPart {
    
    var fields: [FQPart] = []
    
    public init() {}
    
    //@available(*, deprecated: 1.0, message: "will soon become unavailable.")
    @discardableResult
    public func field(_ str: String) -> Self {
        fields.append(str)
        return self
    }
    
    @discardableResult
    public func all<T>(_ table: T.Type) -> Self where T: Model {
        fields.append("\"\(T.FQType.alias)\".*")
        return self
    }
    
    @discardableResult
    public func all<T>(_ alias: FQAlias<T>) -> Self where T: Model {
        fields.append("\"\(alias.alias)\".*")
        return self
    }
    
    @discardableResult
    public func field<T>(_ kp: T, as: String? = nil) -> Self where T: FQUniversalKeyPath {
        _append(kp.queryValue, `as`)
        return self
    }
    
    @discardableResult
    public func field(as: String? = nil, _ json: FQJSON) -> Self {
        fields.append(FQJSON.ForSelectField(json, as: `as`))
        return self
    }
    
    @discardableResult
    public func distinct<T>(_ kp: T, as: String? = nil) -> Self where T: FQUniversalKeyPath {
        _append("DISTINCT \(kp.queryValue)", `as`)
        return self
    }
    
    @discardableResult
    public func `func`<M, T>(_ func: FQAggregate.FunctionWithKeyPath<M>, path kp: T, as: String? = nil) -> Self where M: FQUniversalKeyPath, T: FQUniversalKeyPath {
        let function = `func`.func.replacingOccurrences(of: FQAggregate.valueKey, with: kp.queryValue)
        _append(function, `as`)
        return self
    }
    
    private func _append(_ field: String, _ as: String? = nil) {
        var string = "\(field)"
        if let `as` = `as` {
            string.append(" as \"\(`as`)\"")
        }
        fields.append(string)
    }
    
    public var query: String {
        var result = ""
        
        for (index, field) in fields.enumerated() {
            if index > 0 {
                result.append(",")
                result.append(FluentQueryNextLine)
            }
            result.append(field.query)
        }
        
        return result
    }
    
    func joinAnotherInstance(_ inst: FQSelect) {
        fields.append(contentsOf: inst.fields)
    }
}
