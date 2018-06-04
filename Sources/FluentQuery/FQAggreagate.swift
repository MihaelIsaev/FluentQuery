import Foundation
import Fluent

protocol FQAggregateFuncOption : CustomStringConvertible, Equatable {
    var value: Any { get }
}

public class FQAggregate {
    //MARK: Original functions
    public enum Functions: FQAggregateFuncOption {
        case count(String) //kp
        case sum(String) //kp
        case average(String) //kp
        case min(String) //kp
        case max(String) //kp
        
        public var description: String {
            let description: String
            switch self {
            case .count:
                description = "COUNT(%)"
            case .sum:
                description = "SUM(%)"
            case .average:
                description = "AVG(%)"
            case .min:
                description = "MIN(%)"
            case .max:
                description = "MAX(%)"
            }
            return description
        }
        
        var `func`: String {
            let valueKey = "%"
            return description.replacingOccurrences(of: valueKey, with: "\(value)")
        }
        
        var value: Any {
            let value: Any
            switch self {
            case let .count(v):
                value = v
            case let .sum(v):
                value = v
            case let .average(v):
                value = v
            case let .min(v):
                value = v
            case let .max(v):
                value = v
            }
            return value
        }
        
        public static func ==(lhs: Functions, rhs: Functions) -> Bool {
            return lhs.func == rhs.func
        }
    }
    
    //MARK: Mirror KeyPath based functions
    public enum FuncOptionKP<T, V>: FQAggregateFuncOption where T: Model {
        case count(KeyPath<T, V>)
        case sum(KeyPath<T, V>)
        case average(KeyPath<T, V>)
        case min(KeyPath<T, V>)
        case max(KeyPath<T, V>)
        
        private func formattedPath(_ kp: KeyPath<T, V>) -> String {
            return FluentQuery.formattedPath(T.FQType.self, kp)
        }
        
        var mirror: Functions {
            switch self {
            case .count(let kp): return .count(formattedPath(kp))
            case .sum(let kp): return .sum(formattedPath(kp))
            case .average(let kp): return .average(formattedPath(kp))
            case .min(let kp): return .min(formattedPath(kp))
            case .max(let kp): return .max(formattedPath(kp))
            }
        }
        
        public var description: String {
            return mirror.description
        }
        
        var kp: KeyPath<T, V> {
            switch self {
            case .count(let kp): return kp
            case .sum(let kp): return kp
            case .average(let kp): return kp
            case .min(let kp): return kp
            case .max(let kp): return kp
            }
        }
        
        var `func`: String {
            return mirror.func
        }
        
        var value: Any {
            return mirror.value
        }
        
        public static func ==(lhs: FuncOptionKP, rhs: FuncOptionKP) -> Bool {
            return lhs.func == rhs.func
        }
    }
    
    //MARK: Mirror AliasedKeyPath based functions
    public enum FuncOptionAKP<T, V>: FQAggregateFuncOption where T: Model {
        case count(AliasedKeyPath<T, V>)
        case sum(AliasedKeyPath<T, V>)
        case average(AliasedKeyPath<T, V>)
        case min(AliasedKeyPath<T, V>)
        case max(AliasedKeyPath<T, V>)
        
        var mirror: Functions {
            switch self {
            case .count(let kp): return .count(kp.query)
            case .sum(let kp): return .sum(kp.query)
            case .average(let kp): return .average(kp.query)
            case .min(let kp): return .min(kp.query)
            case .max(let kp): return .max(kp.query)
            }
        }
        
        public var description: String {
            return mirror.description
        }
        
        var kp: AliasedKeyPath<T, V> {
            switch self {
            case .count(let kp): return kp
            case .sum(let kp): return kp
            case .average(let kp): return kp
            case .min(let kp): return kp
            case .max(let kp): return kp
            }
        }
        
        var `func`: String {
            return mirror.func
        }
        
        var value: Any {
            return mirror.value
        }
        
        public static func ==(lhs: FuncOptionAKP, rhs: FuncOptionAKP) -> Bool {
            return lhs.func == rhs.func
        }
    }
    
    //MARK: Mirror for Model only based functions
    public enum FunctionWithModel: FQAggregateFuncOption {
        case count(FluentQuery)
        case sum(FluentQuery)
        case average(FluentQuery)
        case min(FluentQuery)
        case max(FluentQuery)
        
        var mirror: Functions {
            switch self {
            case .count: return .count("(\(value))")
            case .sum: return .sum("(\(value))")
            case .average: return .average("(\(value))")
            case .min: return .min("(\(value))")
            case .max: return .max("(\(value))")
            }
        }
        
        public var description: String {
            return mirror.description
        }
        
        var `func`: String {
            return mirror.func
        }
        
        var value: Any {
            let value: Any
            switch self {
            case let .count(v):
                value = v.query
            case let .sum(v):
                value = v.query
            case let .average(v):
                value = v.query
            case let .min(v):
                value = v.query
            case let .max(v):
                value = v.query
            }
            return value
        }
        
        public static func ==(lhs: FunctionWithModel, rhs: FunctionWithModel) -> Bool {
            return lhs.func == rhs.func
        }
    }
}

