import Foundation

public enum FQOverType: String {
    case partition
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
