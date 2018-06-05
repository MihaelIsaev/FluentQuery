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
    
    public func and(_ predicates: FQPredicateGenericType...)  -> Self {
        for predicate in predicates {
            wheres.append("AND")
            wheres.append(predicate)
        }
        return self
    }
    
    public func and(_ inst: FQWhere)  -> Self {
        joinAnotherInstance(inst, by: "AND")
        return self
    }
    
    public func or(_ predicates: FQPredicateGenericType...)  -> Self {
        for predicate in predicates {
            wheres.append("OR")
            wheres.append(predicate)
        }
        return self
    }
    
    public func or(_ inst: FQWhere)  -> Self {
        joinAnotherInstance(inst, by: "OR")
        return self
    }
    
    public var query: String {
        return wheres.map { $0.query }.joined(separator: " ")
    }
    
    func joinAnotherInstance(_ inst: FQWhere, by: String) {
        if inst.wheres.count > 0 {
            wheres.append(by)
            wheres.append("(")
            for (index, predicate) in inst.wheres.enumerated() {
                if index == 0, ["AND", "OR"].contains(predicate.query) { continue }
                wheres.append(predicate)
            }
            wheres.append(")")
        }
    }
}
