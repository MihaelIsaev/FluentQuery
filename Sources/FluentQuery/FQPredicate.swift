import Foundation
import Fluent

protocol FQPredicateValueProtocol : CustomStringConvertible, Equatable {
    var value: Any? { get }
}

public protocol FQPredicateGenericType: FQPart {
    var query: String { get }
}

public class FQJoinPredicate<M, V, N, W>: FQPart, FQPredicateGenericType where M: Model, N: Model {
    public var query: String
    
    public init (lhs: KeyPath<M, V>, operation: FluentQueryPredicateOperator, rhs: KeyPath<N, W>) {
        query = "\(M.property(lhs)) \(operation.rawValue) \(N.property(rhs))"
    }
    
    public init (lhs: AliasedKeyPath<M, V>, operation: FluentQueryPredicateOperator, rhs: AliasedKeyPath<N, W>) {
        query = "\(lhs.query) \(operation.rawValue) \(rhs.query)"
    }
    
    public init (lhs: AliasedKeyPath<M, V>, operation: FluentQueryPredicateOperator, rhs: KeyPath<N, W>) {
        query = "\(lhs.query) \(operation.rawValue) \(N.property(rhs))"
    }
    
    public init (lhs: KeyPath<M, V>, operation: FluentQueryPredicateOperator, rhs: AliasedKeyPath<N, W>) {
        query = "\(M.property(lhs)) \(operation.rawValue) \(rhs.query)"
    }
    
    //Aggreagate
    public init (lhs: FQAggregate.FuncOptionKP<M, V>, operation: FluentQueryPredicateOperator, rhs: KeyPath<N, W>) {
        query = "\(lhs.func) \(operation.rawValue) \(N.property(rhs))"
    }
    
    public init (lhs: FQAggregate.FuncOptionKP<M, V>, operation: FluentQueryPredicateOperator, rhs: AliasedKeyPath<N, W>) {
        query = "\(lhs.func) \(operation.rawValue) \(rhs.query)"
    }
    
    public init (lhs: FQAggregate.FuncOptionAKP<M, V>, operation: FluentQueryPredicateOperator, rhs: KeyPath<N, W>) {
        query = "\(lhs.func) \(operation.rawValue) \(N.property(rhs))"
    }
    
    public init (lhs: FQAggregate.FuncOptionAKP<M, V>, operation: FluentQueryPredicateOperator, rhs: AliasedKeyPath<N, W>) {
        query = "\(lhs.func) \(operation.rawValue) \(rhs.query)"
    }
}

public class FQPredicate<M, V>: FQPart, FQPredicateGenericType  where M: Model{
    enum FQPredicateValue: FQPredicateValueProtocol {
        case simple(V)
        case simpleOptional(V?)
        case simpleAny(Any)
        case array([V])
        case arrayOfOptionals([V?])
        case arrayOfAny([Any])
        case string(String)
        
        var description: String {
            let description: String
            switch self {
            case .simple:
                description = "simple"
            case .simpleOptional:
                description = "simpleOptional"
            case .simpleAny:
                description = "simpleAny"
            case .array:
                description = "array"
            case .arrayOfOptionals:
                description = "arrayOfOptionals"
            case .arrayOfAny:
                description = "arrayOfAny"
            case .string:
                description = "string"
            }
            return description
        }
        
        var value: Any? {
            let value: Any?
            switch self {
            case let .simple(v):
                value = v
            case let .simpleOptional(v):
                value = v
            case let .simpleAny(v):
                value = v
            case let .array(v):
                value = v
            case let .arrayOfOptionals(v):
                value = v
            case let .arrayOfAny(v):
                value = v
            case let .string(v):
                value = v
            }
            return value
        }
        
        static func ==(lhs: FQPredicateValue, rhs: FQPredicateValue) -> Bool {
            return lhs.description == rhs.description
        }
    }
    var kp: KeyPath<M, V>
    var operation: FluentQueryPredicateOperator
    var value: FQPredicateValue
    var property: String
    public init (kp: KeyPath<M, V>, operation: FluentQueryPredicateOperator, value: FQPredicateValue) {
        self.property = M.property(kp)
        self.kp = kp
        self.operation = operation
        self.value = value
    }
    
    public init (kp aliased: AliasedKeyPath<M, V>, operation: FluentQueryPredicateOperator, value: FQPredicateValue) {
        self.property = aliased.query
        self.kp = aliased.kp
        self.operation = operation
        self.value = value
    }
    
    public init (kp func: FQAggregate.FuncOptionKP<M, V>, operation: FluentQueryPredicateOperator, value: FQPredicateValue) {
        self.property = `func`.func
        self.kp = `func`.kp
        self.operation = operation
        self.value = value
    }
    
    public init (kp func: FQAggregate.FuncOptionAKP<M, V>, operation: FluentQueryPredicateOperator, value: FQPredicateValue) {
        self.property = `func`.func
        self.kp = `func`.kp.kp
        self.operation = operation
        self.value = value
    }
    
    private func formatValue(_ v: Any?) -> String {
        guard let v = v else {
            return "NULL"
        }
        switch v {
        case is String:
            if let v = v as? String {
                if let first = v.first {
                    if "\(first)" == "(" {
                        return v
                    }
                }
            }
            return "'\(v)'"
        case is UUID: if let v = v as? UUID { return "'\(v.uuidString)'" } else { fallthrough }
        case is Bool: if let v = v as? Bool { return "\(v ? 1 : 0)" } else { fallthrough }
        case is Int: fallthrough
        case is Int8: fallthrough
        case is Int16: fallthrough
        case is Int32: fallthrough
        case is Int64: fallthrough
        case is UInt: fallthrough
        case is UInt8: fallthrough
        case is UInt16: fallthrough
        case is UInt32: fallthrough
        case is UInt64: fallthrough
        case is Float: fallthrough
        case is Double: return "\(v)"
        default: return "\(v)"
        }
    }
    
    public var query: String {
        var result = "\(property) \(operation.rawValue) "
        switch value {
        case .simpleAny(let v):
            result.append(formatValue(v))
        case .simple(let v):
            result.append(formatValue(v))
        case .simpleOptional(let v):
            result.append(formatValue(v))
        case .array(let v):
            result.append("(\(v.map { "\(formatValue($0))" }.joined(separator: ",")))")
        case .arrayOfOptionals(let v):
            result.append("(\(v.map { "\(formatValue($0))" }.joined(separator: ",")))")
        case .arrayOfAny(let v):
            result.append("(\(v.map { "\(formatValue($0))" }.joined(separator: ",")))")
        case .string(let v):
            result.append(formatValue(v))
        }
        return result
            .replacingOccurrences(of: "= NULL", with: "IS NULL")
            .replacingOccurrences(of: "!= NULL", with: "IS NOT NULL")
            .replacingOccurrences(of: "= nil", with: "IS NULL")
            .replacingOccurrences(of: "!= nil", with: "IS NOT NULL")
    }
}

// ==
public func == <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .equal, value: .simple(rhs))
}
public func == <M, V>(lhs: KeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .equal, value: .simpleOptional(rhs))
}
public func == <M, V: RawRepresentable>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .equal, value: .simpleAny(rhs.rawValue))
}
// == aliased
public func == <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .equal, value: .simple(rhs))
}
public func == <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .equal, value: .simpleOptional(rhs))
}
public func == <M, V: RawRepresentable>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .equal, value: .simpleAny(rhs.rawValue))
}
// == for join
public func == <M, V, N, W>(lhs: KeyPath<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .equal, rhs: rhs)
}
// == aliased for join
public func == <M, V, N, W>(lhs: AliasedKeyPath<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .equal, rhs: rhs)
}
public func == <M, V, N, W>(lhs: AliasedKeyPath<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .equal, rhs: rhs)
}
public func == <M, V, N, W>(lhs: KeyPath<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .equal, rhs: rhs)
}
// == aggregate function
public func == <M, V, K>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .equal, value: .simpleAny(rhs))
}
public func == <M, V, K>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .equal, value: .simpleAny(rhs))
}
public func == <M, V>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .equal, value: .string("(\(rhs.query))"))
}
public func == <M, V>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .equal, value: .string("(\(rhs.query))"))
}
public func == <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .equal, rhs: rhs)
}
public func == <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .equal, rhs: rhs)
}
public func == <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .equal, rhs: rhs)
}
public func == <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .equal, rhs: rhs)
}

// !=
public func != <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notEqual, value: .simple(rhs))
}
public func != <M, V>(lhs: KeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notEqual, value: .simpleOptional(rhs))
}
public func != <M, V: RawRepresentable>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notEqual, value: .simpleAny(rhs.rawValue))
}
// != aliased
public func != <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notEqual, value: .simple(rhs))
}
public func != <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notEqual, value: .simpleOptional(rhs))
}
public func != <M, V: RawRepresentable>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notEqual, value: .simpleAny(rhs.rawValue))
}
// != for join
public func != <M, V, N, W>(lhs: KeyPath<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .notEqual, rhs: rhs)
}
// != aliased for join
public func != <M, V, N, W>(lhs: AliasedKeyPath<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .notEqual, rhs: rhs)
}
public func != <M, V, N, W>(lhs: AliasedKeyPath<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .notEqual, rhs: rhs)
}
public func != <M, V, N, W>(lhs: KeyPath<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .notEqual, rhs: rhs)
}
// != aggregate function
public func != <M, V, K>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .notEqual, value: .simpleAny(rhs))
}
public func != <M, V, K>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .notEqual, value: .simpleAny(rhs))
}
public func != <M, V>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notEqual, value: .string("(\(rhs.query))"))
}
public func != <M, V>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notEqual, value: .string("(\(rhs.query))"))
}
public func != <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .notEqual, rhs: rhs)
}
public func != <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .notEqual, rhs: rhs)
}
public func != <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .notEqual, rhs: rhs)
}
public func != <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .notEqual, rhs: rhs)
}

// >
public func > <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThan, value: .simple(rhs))
}
public func > <M, V>(lhs: KeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThan, value: .simpleOptional(rhs))
}
public func > <M, V: RawRepresentable>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThan, value: .simpleAny(rhs.rawValue))
}
// > aliased
public func > <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThan, value: .simple(rhs))
}
public func > <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThan, value: .simpleOptional(rhs))
}
public func > <M, V: RawRepresentable>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThan, value: .simpleAny(rhs.rawValue))
}
// > aggregate function
public func > <M, V, K>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .greaterThan, value: .simpleAny(rhs))
}
public func > <M, V, K>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .greaterThan, value: .simpleAny(rhs))
}
public func > <M, V>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThan, value: .string("(\(rhs.query))"))
}
public func > <M, V>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThan, value: .string("(\(rhs.query))"))
}
public func > <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .greaterThan, rhs: rhs)
}
public func > <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .greaterThan, rhs: rhs)
}
public func > <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .greaterThan, rhs: rhs)
}
public func > <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .greaterThan, rhs: rhs)
}

// <
public func < <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThan, value: .simple(rhs))
}
public func < <M, V>(lhs: KeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThan, value: .simpleOptional(rhs))
}
public func < <M, V: RawRepresentable>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThan, value: .simpleAny(rhs.rawValue))
}
// < aliased
public func < <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThan, value: .simple(rhs))
}
public func < <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThan, value: .simpleOptional(rhs))
}
public func < <M, V: RawRepresentable>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThan, value: .simpleAny(rhs.rawValue))
}
// < aggregate function
public func < <M, V, K>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .lessThan, value: .simpleAny(rhs))
}
public func < <M, V, K>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .lessThan, value: .simpleAny(rhs))
}
public func < <M, V>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThan, value: .string("(\(rhs.query))"))
}
public func < <M, V>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThan, value: .string("(\(rhs.query))"))
}
public func < <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .lessThan, rhs: rhs)
}
public func < <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .lessThan, rhs: rhs)
}
public func < <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .lessThan, rhs: rhs)
}
public func < <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .lessThan, rhs: rhs)
}

// >=
public func >= <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThanOrEqual, value: .simple(rhs))
}
public func >= <M, V>(lhs: KeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThanOrEqual, value: .simpleOptional(rhs))
}
public func >= <M, V: RawRepresentable>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThanOrEqual, value: .simpleAny(rhs.rawValue))
}
// >= aliased
public func >= <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThanOrEqual, value: .simple(rhs))
}
public func >= <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThanOrEqual, value: .simpleOptional(rhs))
}
public func >= <M, V: RawRepresentable>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThanOrEqual, value: .simpleAny(rhs.rawValue))
}
// >= aggregate function
public func >= <M, V, K>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .greaterThanOrEqual, value: .simpleAny(rhs))
}
public func >= <M, V, K>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .greaterThanOrEqual, value: .simpleAny(rhs))
}
public func >= <M, V>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThanOrEqual, value: .string("(\(rhs.query))"))
}
public func >= <M, V>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .greaterThanOrEqual, value: .string("(\(rhs.query))"))
}
public func >= <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .greaterThanOrEqual, rhs: rhs)
}
public func >= <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .greaterThanOrEqual, rhs: rhs)
}
public func >= <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .greaterThanOrEqual, rhs: rhs)
}
public func >= <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .greaterThanOrEqual, rhs: rhs)
}

// <=
public func <= <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThanOrEqual, value: .simple(rhs))
}
public func <= <M, V>(lhs: KeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThanOrEqual, value: .simpleOptional(rhs))
}
public func <= <M, V: RawRepresentable>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThanOrEqual, value: .simpleAny(rhs.rawValue))
}
// <= aliased
public func <= <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThanOrEqual, value: .simple(rhs))
}
public func <= <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V?) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThanOrEqual, value: .simpleOptional(rhs))
}
public func <= <M, V: RawRepresentable>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThanOrEqual, value: .simpleAny(rhs.rawValue))
}
// <= aggregate function
public func <= <M, V, K>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .lessThanOrEqual, value: .simpleAny(rhs))
}
public func <= <M, V, K>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: K) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .lessThanOrEqual, value: .simpleAny(rhs))
}
public func <= <M, V>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThanOrEqual, value: .string("(\(rhs.query))"))
}
public func <= <M, V>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .lessThanOrEqual, value: .string("(\(rhs.query))"))
}
public func <= <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .lessThanOrEqual, rhs: rhs)
}
public func <= <M, V, N, W>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .lessThanOrEqual, rhs: rhs)
}
public func <= <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: KeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .lessThanOrEqual, rhs: rhs)
}
public func <= <M, V, N, W>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: AliasedKeyPath<N, W>) -> FQPredicateGenericType where M: Model, N: Model {
    return FQJoinPredicate(lhs: lhs, operation: .lessThanOrEqual, rhs: rhs)
}

// IN
public func ~~ <M, V>(lhs: KeyPath<M, V>, rhs: [V]) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .in, value: .array(rhs))
}
public func ~~ <M, V>(lhs: KeyPath<M, V>, rhs: [V?]) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .in, value: .arrayOfOptionals(rhs))
}
public func ~~ <M, V: RawRepresentable>(lhs: KeyPath<M, V>, rhs: [V]) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .in, value: .arrayOfAny(rhs.map { $0.rawValue }))
}
// IN aliased SUBQUERY
public func ~~ <M, V>(lhs: AliasedKeyPath<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .in, value: .string("(\(rhs.query))"))
}
public func ~~ <M, V>(lhs: AliasedKeyPath<M, V>, rhs: [V?]) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .in, value: .arrayOfOptionals(rhs))
}
public func ~~ <M, V: RawRepresentable>(lhs: AliasedKeyPath<M, V>, rhs: [V]) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .in, value: .arrayOfAny(rhs.map { $0.rawValue }))
}
// IN SUBQUERY
public func ~~ <M, V>(lhs: KeyPath<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .in, value: .string("(\(rhs.query))"))
}
// IN aggregate function
public func ~~ <M, V, K>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: [K]) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .in, value: .arrayOfAny(rhs))
}
public func ~~ <M, V, K>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: [K]) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .in, value: .arrayOfAny(rhs))
}
public func ~~ <M, V>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .in, value: .string("(\(rhs.query))"))
}
public func ~~ <M, V>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .in, value: .string("(\(rhs.query))"))
}

// NOT IN
public func !~ <M, V>(lhs: KeyPath<M, V>, rhs: [V]) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notIn, value: .array(rhs))
}
public func !~ <M, V>(lhs: KeyPath<M, V>, rhs: [V?]) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notIn, value: .arrayOfOptionals(rhs))
}
public func !~ <M, V: RawRepresentable>(lhs: KeyPath<M, V>, rhs: [V]) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notIn, value: .arrayOfAny(rhs.map { $0.rawValue }))
}
// NOT IN aliased
public func !~ <M, V>(lhs: AliasedKeyPath<M, V>, rhs: [V]) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notIn, value: .array(rhs))
}
public func !~ <M, V>(lhs: AliasedKeyPath<M, V>, rhs: [V?]) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notIn, value: .arrayOfOptionals(rhs))
}
public func !~ <M, V: RawRepresentable>(lhs: AliasedKeyPath<M, V>, rhs: [V]) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notIn, value: .arrayOfAny(rhs.map { $0.rawValue }))
}
// NOT IN aggregate function
public func !~ <M, V, K>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: [K]) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .notIn, value: .arrayOfAny(rhs))
}
public func !~ <M, V, K>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: [K]) -> FQPredicateGenericType where M: Model, K: Numeric {
    return FQPredicate(kp: lhs, operation: .notIn, value: .arrayOfAny(rhs))
}
public func !~ <M, V>(lhs: FQAggregate.FuncOptionKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notIn, value: .string("(\(rhs.query))"))
}
public func !~ <M, V>(lhs: FQAggregate.FuncOptionAKP<M, V>, rhs: FluentQuery) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notIn, value: .string("(\(rhs.query))"))
}

// LIKE
infix operator ~=
public func ~= <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .like, value: .string("%\(rhs)"))
}
public func ~= <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .like, value: .string("%\(rhs)"))
}
infix operator =~
public func =~ <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .like, value: .string("\(rhs)%"))
}
public func =~ <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .like, value: .string("\(rhs)%"))
}
public func ~~ <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .like, value: .string("%\(rhs)%"))
}
public func ~~ <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .like, value: .string("%\(rhs)%"))
}

// NOT LIKE
infix operator !~=
public func !~= <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notLike, value: .string("%\(rhs)"))
}
public func !~= <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notLike, value: .string("%\(rhs)"))
}
infix operator !=~
public func !=~ <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notLike, value: .string("\(rhs)%"))
}
public func !=~ <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notLike, value: .string("\(rhs)%"))
}
infix operator !~~
public func !~~ <M, V>(lhs: KeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notLike, value: .string("%\(rhs)%"))
}
public func !~~ <M, V>(lhs: AliasedKeyPath<M, V>, rhs: V) -> FQPredicateGenericType where M: Model {
    return FQPredicate(kp: lhs, operation: .notLike, value: .string("%\(rhs)%"))
}

//FUTURE: create method which can handle two predicates
//FUTURE: generate paths like this `(r."carEquipment"->>'interior')::uuid` with type casting
