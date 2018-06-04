import Foundation
import Fluent

public class FQWhere: FQPart {
    var wheres: [FQPart] = []
    
    public init(_ predicates: FQPredicateGenericType...) {
        for (index, predicate) in predicates.enumerated() {
            if index > 0 {
                wheres.append("AND")
            }
            wheres.append(predicate)
        }
    }
    
    public func groupStart() -> Self {
        wheres.append("(")
        return self
    }
    
    public func groupEnd() -> Self {
        wheres.append(")")
        return self
    }
    
    public func and(_ predicates: FQPredicateGenericType...)  -> Self {
        for predicate in predicates {
            wheres.append("AND")
            wheres.append(predicate)
        }
        return self
    }
    
    public func or(_ predicates: FQPredicateGenericType...)  -> Self {
        for predicate in predicates {
            wheres.append("OR")
            wheres.append(predicate)
        }
        return self
    }
    
    public var query: String {
        return wheres.map { $0.query }.joined(separator: " ")
    }
}
