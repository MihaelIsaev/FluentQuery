import Foundation
import Fluent

public class FQGroupBy: FQPart {
    var parts: [FQPart] = []
    
    public init () {}
    
    public init<M, V>(_ kp: KeyPath<M, V>) where M: Model {
        add(kp)
    }
    
    public init<M, V>(_ alias: AliasedKeyPath<M, V>) where M: Model {
        add(alias)
    }
    
    @discardableResult
    public func add<M, V>(_ kp: KeyPath<M, V>) -> Self where M: Model {
        parts.append(FluentQuery.formattedPath(M.FQType.self, kp))
        return self
    }
    
    @discardableResult
    public func add<M, V>(_ alias: AliasedKeyPath<M, V>) -> Self {
        parts.append(alias.query)
        return self
    }
    
    @discardableResult
    public func and<M, V>(_ kp: KeyPath<M, V>) -> Self where M: Model {
        return add(kp)
    }
    
    @discardableResult
    public func and<M, V>(_ alias: AliasedKeyPath<M, V>) -> Self where M: Model {
        return add(alias)
    }
    
    public var query: String {
        return parts.map { $0.query }.joined(separator: ", ")
    }
}
