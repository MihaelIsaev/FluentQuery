import Foundation
import Fluent

protocol FQAggregateFuncOption : CustomStringConvertible, Equatable {
    var value: Any { get }
}

public protocol FQAggregateFuncOptionKP {
    associatedtype Root: FQUniversalKeyPath
}

public class FQAggregate {
    static let valueKey = "%"
    
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
                description = "COUNT\(FQAggregate.valueKey.roundBracketted)"
            case .sum:
                description = "SUM\(FQAggregate.valueKey.roundBracketted)"
            case .average:
                description = "AVG\(FQAggregate.valueKey.roundBracketted)"
            case .min:
                description = "MIN\(FQAggregate.valueKey.roundBracketted)"
            case .max:
                description = "MAX\(FQAggregate.valueKey.roundBracketted)"
            }
            return description
        }
        
        var `func`: String {
            return description.replacingOccurrences(of: FQAggregate.valueKey, with: "\(value)")
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
    public enum FunctionWithKeyPath<UKP>: FQAggregateFuncOption, FQAggregateFuncOptionKP where UKP: FQUniversalKeyPath {
        public typealias Root = UKP
        
        case count(UKP)
        case sum(UKP)
        case average(UKP)
        case min(UKP)
        case max(UKP)
        
        var mirror: Functions {
            switch self {
            case .count(let kp): return .count(kp.queryValue)
            case .sum(let kp): return .sum(kp.queryValue)
            case .average(let kp): return .average(kp.queryValue)
            case .min(let kp): return .min(kp.queryValue)
            case .max(let kp): return .max(kp.queryValue)
            }
        }
        
        public var description: String {
            return mirror.description
        }
        
        var kp: UKP {
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
        
        public static func ==(lhs: FunctionWithKeyPath, rhs: FunctionWithKeyPath) -> Bool {
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
            case .count: return .count("\(value.roundBracketted)")
            case .sum: return .sum("\(value.roundBracketted)")
            case .average: return .average("\(value.roundBracketted)")
            case .min: return .min("\(value.roundBracketted)")
            case .max: return .max("\(value.roundBracketted)")
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

