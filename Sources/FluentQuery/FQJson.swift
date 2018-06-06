import Foundation
import Fluent

public class FQJSON: FQPart {
    class ForSelectField: FQPart {
        var object: FQJSON
        var asKey: String?
        init (_ object: FQJSON, as asKey: String? = nil) {
            self.object = object
            self.asKey = asKey
        }
        var query: String {
            var result = object.query
            if let asKey = asKey {
                result.append(" as \(asKey.doubleQuotted)")
            }
            return result
        }
    }
    public enum Mode: String {
        case normal = "json"
        case binary = "jsonb"
    }
    
    public var mode: Mode
    
    public init(_ mode: Mode) {
        self.mode = mode
    }
    
    var fields: [FQPart] = []
    
    @discardableResult
    public func field(_ key: String, raw: String) -> Self {
        fields.append("\(key.singleQuotted), \(raw.roundBracketted)")
        return self
    }
    
    @discardableResult
    public func field(_ key: String, _ value: String) -> Self {
        fields.append("\(key.singleQuotted), \(value.doubleQuotted)")
        return self
    }
    
    @discardableResult
    public func field(_ key: String, _ value: FQPart) -> Self {
        fields.append("\(key.singleQuotted), \(value.query)")
        return self
    }
    
    @discardableResult
    public func field<T, V>(_ key: String, _ kp: KeyPath<T, V>) -> Self where T: Model {
        return field(key, T.FQType.self, kp)
    }
    
    @discardableResult
    public func field<T, V>(_ key: String, _ aliased: AliasedKeyPath<T, V>) -> Self where T: Model {
        fields.append("\(key.singleQuotted), \(FluentQuery.formattedPath(aliased.query, aliased.kp))")
        return self
    }
    
    //MARK: Func
    @discardableResult
    public func field<T, V>(_ key: String, func: FuncOptionKP<T, V>) -> Self where T: Model {
        return field(key, raw: `func`.func)
    }
    @discardableResult
    public func field<T, V>(_ key: String, func: FuncOptionAKP<T, V>) -> Self where T: Model {
        return field(key, raw: `func`.func)
    }
    @discardableResult
    public func field<T>(_ key: String, func: FunctionWithModelAlias<T>) -> Self where T: Model {
        return field(key, raw: `func`.func)
    }
    @discardableResult
    public func field<T>(_ key: String, func: FunctionWithModel<T>) -> Self where T: Model {
        return field(key, raw: `func`.func)
    }
    
    @discardableResult
    public func field<T, V>(_ key: String, _ kp: KeyPath<T, V>, func: String, valueKey: String = "%") -> Self where T: Model {
        return field(key, T.FQType.self, kp, func: `func`, valueKey: valueKey)
    }
    
    @discardableResult
    public func field<T, V>(_ key: String, _ table: FQTable<T>.Type, _ kp: KeyPath<T, V>, func: String, valueKey: String = "%") -> Self where T: Model {
        return field(key, raw: `func`.replacingOccurrences(of: valueKey, with: FluentQuery.formattedPath(table, kp)))
    }
    
    //MARK: Count with filter
    @discardableResult
    public func field<T, V>(_ key: String, count kp: KeyPath<T, V>, _ wheres: FQWhere...) -> Self where T: Model {
        return field(key, T.FQType.self, kp) //TODO: implement JSON field COUNT(_) filter (where _)
    }
    
    @discardableResult
    public func field<T, V>(_ key: String, _ table: FQTable<T>.Type, _ kp: KeyPath<T, V>) -> Self where T: Model {
        fields.append("\(key.singleQuotted), \(FluentQuery.formattedPath(table, kp))")
        return self
    }
    
    public var query: String {
        var result = "\(mode.rawValue)_build_object"
        result.append("(")
        for (index, field) in fields.enumerated() {
            if index > 0 {
                result.append(",")
            }
            result.append(field.query)
        }
        result.append(")")
        return result
    }
}

protocol FQJSONFuncOption : CustomStringConvertible, Equatable {
    var value: Any { get }
}

extension FQJSON {
    //MARK: Original functions
    public enum Functions: FQJSONFuncOption {
        typealias KPAndWheres = (kp: String, wheres: String)
        
        case rowToJson(String) //m
        case extractEpochFromTime(String) //kp
        case count(String) //kp
        case countWhere(String, String) //kp, w
        case empty() //temporary
        
        public var description: String {
            let description: String
            switch self {
            case .rowToJson:
                description = "SELECT row_to_json(%)"
            case .extractEpochFromTime:
                description = "extract(epoch from %)"
            case .count:
                description = "COUNT(%)"
            case .countWhere:
                description = "COUNT(%) filter (where $)"
            case .empty:
                description = ""
            }
            return description
        }
        
        var `func`: String {
            let valueKey = "%"
            let whereKey = "$"
            switch self {
            case .rowToJson: fallthrough
            case .extractEpochFromTime: fallthrough
            case .count:
                return description.replacingOccurrences(of: valueKey, with: "\(value)")
            case .countWhere:
                if let sss = value as? KPAndWheres {
                    return description
                        .replacingOccurrences(of: valueKey, with: sss.kp)
                        .replacingOccurrences(of: whereKey, with: sss.wheres)
                }
                return "<error>"
            case .empty: return "<empty>"
            }
        }
        
        var value: Any {
            let value: Any
            switch self {
            case let .rowToJson(b):
                value = b
            case let .extractEpochFromTime(t):
                value = t
            case let .count(v):
                value = v
            case let .countWhere(v):
                value = KPAndWheres(kp: v.0, wheres: v.1)
            case .empty:
                value = ""
            }
            return value
        }
        
        public static func ==(lhs: Functions, rhs: Functions) -> Bool {
            return lhs.func == rhs.func
        }
    }
    
    //MARK: Mirror KeyPath based functions
    public enum FuncOptionKP<T, V>: FQJSONFuncOption where T: Model {
        typealias KPAndWheres = (kp: KeyPath<T, V>, wheres: FQWhere)
        
        case extractEpochFromTime(KeyPath<T, V>)
        case count(KeyPath<T, V>)
        case countWhere(KeyPath<T, V>, FQWhere)
        
        private func formattedPath(_ kp: KeyPath<T, V>) -> String {
            return FluentQuery.formattedPath(T.FQType.self, kp)
        }
        
        var mirror: Functions {
            switch self {
            case .extractEpochFromTime(let kp): return .extractEpochFromTime(formattedPath(kp))
            case .count(let kp): return .count(formattedPath(kp))
            case .countWhere(let v): return .countWhere(formattedPath(v.0), v.1.query)
            }
        }
        
        public var description: String {
            return mirror.description
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
    public enum FuncOptionAKP<T, V>: FQJSONFuncOption where T: Model {
        typealias KPAndWheres = (kp: AliasedKeyPath<T, V>, wheres: FQWhere)
        
        case extractEpochFromTime(AliasedKeyPath<T, V>)
        case count(AliasedKeyPath<T, V>)
        case countWhere(AliasedKeyPath<T, V>, FQWhere)
        
        var mirror: Functions {
            switch self {
            case .extractEpochFromTime(let kp): return .extractEpochFromTime(kp.query)
            case .count(let kp): return .count(kp.query)
            case .countWhere(let v): return .countWhere(v.0.query, v.1.query)
            }
        }
        
        public var description: String {
            return mirror.description
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
    
    //MARK: Mirror for ModelAlias only based functions
    public enum FunctionWithModelAlias<T>: FQJSONFuncOption where T: Model {
        case rowToJson(FQAlias<T>)
        case none()
        
        var mirror: Functions {
            switch self {
            case .rowToJson(let v): return .rowToJson("\(v.alias.doubleQuotted)")
            case .none: return .empty()
            }
        }
        
        public var description: String {
            return mirror.description
        }
        
        var `func`: String {
            return mirror.func
        }
        
        var value: Any {
            return mirror.value
        }
        
        public static func ==(lhs: FunctionWithModelAlias, rhs: FunctionWithModelAlias) -> Bool {
            return lhs.func == rhs.func
        }
    }
    
    //MARK: Mirror for Model only based functions
    public enum FunctionWithModel<T>: FQJSONFuncOption where T: Model {
        case rowToJson(T.Type)
        case none()
        
        var mirror: Functions {
            switch self {
            case .rowToJson: return .rowToJson("\(T.FQType.alias.doubleQuotted)")
            case .none: return .empty()
            }
        }
        
        public var description: String {
            return mirror.description
        }
        
        var `func`: String {
            return mirror.func
        }
        
        var value: Any {
            return mirror.value
        }
        
        public static func ==(lhs: FunctionWithModel, rhs: FunctionWithModel) -> Bool {
            return lhs.func == rhs.func
        }
    }
}
