import Foundation
import Fluent

public class FQOrderBy: FQPart {
    public enum Mode: String {
        case descending = "DESC"
        case ascending = "ASC"
    }
    
    public struct Data: FQPart {
        var path: String
        var mode: Mode
        
        public init<M, V>(_ kp: KeyPath<M, V>, _ mode: Mode) where M: Model {
            self.path = FluentQuery.formattedPath(M.FQType.self, kp)
            self.mode = mode
        }
        
        public init<M, V>(_ alias: AliasedKeyPath<M, V>, _ mode: Mode) {
            self.path = alias.query
            self.mode = mode
        }
        
        public var query: String {
            return "\(path) \(mode.rawValue)"
        }
    }
    
    var parts: [Data] = []
    
    public init () {}
    
    public init<M, V>(_ kp: KeyPath<M, V>, _ mode: Mode) where M: Model {
        add(kp, mode)
    }
    
    public init<M, V>(_ alias: AliasedKeyPath<M, V>, _ mode: Mode) where M: Model {
        add(alias, mode)
    }
    
    @discardableResult
    public func add<M, V>(_ kp: KeyPath<M, V>, _ mode: Mode) -> Self where M: Model {
        parts.append(Data(kp, mode))
        return self
    }
    
    @discardableResult
    public func add<M, V>(_ alias: AliasedKeyPath<M, V>, _ mode: Mode) -> Self where M: Model {
        parts.append(Data(alias, mode))
        return self
    }
    
    @discardableResult
    public func and<M, V>(_ kp: KeyPath<M, V>, _ mode: Mode) -> Self where M: Model {
        return add(kp, mode)
    }
    
    @discardableResult
    public func and<M, V>(_ alias: AliasedKeyPath<M, V>, _ mode: Mode) -> Self where M: Model {
        return add(alias, mode)
    }
    
    public var query: String {
        return parts.map { $0.query }.joined(separator: ", ")
    }
}

