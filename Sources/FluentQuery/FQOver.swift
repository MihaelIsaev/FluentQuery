import Foundation

public enum FQOverType: String {
    case partition
}

public enum FQOverFunction: FQPart {
    case rowNumber
    case rank
    case denseRank
    case percentRank
    case cumeDist
    case ntile(Int64)
    case lag(Any, Int64, Any)
    case lead(Any, Int64, Any)
    case firstValue(Any)
    case lastValue(Any)
    case nthValue(Any, Int64)
    
    public var name: String {
        switch self {
        case .rowNumber: return "row_number"
        case .rank: return "rank"
        case .denseRank: return "dense_rank"
        case .percentRank: return "percent_rank"
        case .cumeDist: return "cume_dist"
        case .ntile: return "ntile"
        case .lag: return "lag"
        case .lead: return "lead"
        case .firstValue: return "first_value"
        case .lastValue: return "last_value"
        case .nthValue: return "nth_value"
        }
    }
    
    public var query: String {
        let prefix = name
        switch self {
        case let .ntile(numBuckets): return prefix + "\(numBuckets)".roundBracketted
        case let .lag(value, offset, `default`): return prefix + "\(value), \(offset), \(`default`)".roundBracketted
        case let .lead(value, offset, `default`): return prefix + "\(value), \(offset), \(`default`)".roundBracketted
        case let .firstValue(value): return prefix + "\(value)".roundBracketted
        case let .lastValue(value): return prefix + "\(value)".roundBracketted
        case let .nthValue(value, nth): return prefix + "\(value), \(nth)".roundBracketted
        default: return prefix + "()"
        }
    }
}

public class FQOver {
    
    public var type: FQOverType
    public var fields: [FQPart] = []
    public var orderBy: FQOrderBy?
    
    public init(_ type: FQOverType) {
        self.type = type
    }
    
    public func by(_ keyPaths: FQUniversalKeyPathSimple...) {
        fields = keyPaths.map { $0.queryValue }
    }
    
    public func by(_ keyPaths: [FQUniversalKeyPathSimple]) {
        fields = keyPaths.map { $0.queryValue }
    }
    
    @discardableResult
    public func orderBy(_ orderBy: FQOrderBy) -> Self {
        if let w = self.orderBy {
            w.joinAnotherInstance(orderBy)
        } else {
            self.orderBy = orderBy
        }
        return self
    }
    
    @discardableResult
    public func orderBy(_ enums: OrderByEnum...) -> Self {
        let orderBy = FQOrderBy(enums)
        if let w = self.orderBy {
            w.joinAnotherInstance(orderBy)
        } else {
            self.orderBy = orderBy
        }
        return self
    }
}

extension FQOver: FQPart {
    public var query: String {
        var result = "OVER(\(type.rawValue) BY"
        result.append(FluentQueryNextLine)
        result.append(fields.map { $0.query }.joined(separator: ", "))
        if let orderBy = orderBy {
            result.append(FluentQueryNextLine)
            result.append("ORDER BY")
            result.append(FluentQueryNextLine)
            result.append(orderBy.query)
        }
        result.append(")")
        return result
    }
}

extension FQOver: CustomStringConvertible {
    public var description: String {
        return query
    }
}
