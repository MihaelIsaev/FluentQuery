import Foundation
import Fluent

public class AliasedKeyPath<M, V>: FQPart where M: Model {
    var alias: String
    var kp: KeyPath<M, V>
    init(_ alias: String, _ kp: KeyPath<M, V>) {
        self.alias = alias
        self.kp = kp
    }
    
    public var query: String {
        return FluentQuery.formattedPath(alias, kp)
    }
}

public class FQAlias<M>: FQPart where M: Model {
    var name: String {
        return M.entity
    }
    var alias: String
    
    public init(_ alias: String) {
        self.alias = alias
    }
    
    //MARK: SQLQueryPart
    
    public var query: String {
        return "\"\(name)\" as \"\(alias)\""
    }
    
    public func k<V>(_ kp: KeyPath<M, V>) -> AliasedKeyPath<M, V> {
        return AliasedKeyPath(alias, kp)
    }
}

public protocol FQUniversalKeyPath {
    var queryValue: String { get }
}

extension KeyPath: FQUniversalKeyPath where Root: Model {
    public var queryValue: String {
        return FQGetKeyPath(self)
    }
}

extension AliasedKeyPath: FQUniversalKeyPath {
    public var queryValue: String {
        return FQGetKeyPath(self)
    }
}

public protocol FQUniversalModel {
    var queryValue: String { get }
}
