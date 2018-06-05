import Foundation
import Fluent

public enum FluentQueryPredicateOperator: String {
    case equal = "="
    case notEqual = "!="
    case lessThan = "<"
    case greaterThan = ">"
    case lessThanOrEqual = "<="
    case greaterThanOrEqual = ">="
    case `in` = "IN"
    case notIn = "NOT IN"
    case between = "BETWEEN"
    case like = "LIKE"
    case notLike = "NOT LIKE"
    case isNull = "IS NULL"
    case isNotNull = "IS NOT NULL"
}

public class FluentQuery: FQPart {
    public var selectFields: [FQPart] = []
    public var froms: [FQPart] = []
    public var joins: [FQJoinGenericType] = []
    public var `where`: FQWhere?
    public var groupBy: FQGroupBy?
    public var having: FQWhere?
    public var orderBy: FQOrderBy?
    public var offset: Int?
    public var limit: Int?
    
    public init() {}
    
    public func select(_ str: String) -> Self {
        selectFields.append(str)
        return self
    }
    
    public func select<T, V>(_ kp: KeyPath<T, V>) -> Self where T: Model {
        selectFields.append(FluentQuery.formattedPath(T.FQType.self, kp))
        return self
    }
    
    public func select<T, V>(_ alias: AliasedKeyPath<T, V>) -> Self where T: Model {
        selectFields.append(alias.query)
        return self
    }
    
    public func select<T, V>(distinct kp: KeyPath<T, V>) -> Self where T: Model {
        selectFields.append("DISTINCT \(FluentQuery.formattedPath(T.FQType.self, kp))")
        return self
    }
    
    public func select<T, V>(distinct alias: AliasedKeyPath<T, V>) -> Self where T: Model {
        selectFields.append(alias.query)
        return self
    }
    
    public func select<T, V>(count table: FQTable<T>.Type, path kp: KeyPath<T, V>, as asKey: String) -> Self {
        selectFields.append("COUNT(\(FluentQuery.formattedPath(table, kp))) as \"\(asKey)\"")
        return self
    }
    
    public func select(as: String? = nil, _ json: FQJSON) -> Self {
        selectFields.append(FQJSON.ForSelectField(json, as: `as`))
        return self
    }
    
    public func selectField(_ jsonObject: FQJSON, as asKey: String?) -> Self {
        var string = jsonObject.query
        if let asKey = asKey {
            string.append(" as \"\(asKey)\"")
        }
        selectFields.append(string)
        return self
    }
    
    public func from(_ db: String, as asKey: String) -> Self {
        froms.append("\"\(db)\" as \"\(asKey)\"")
        return self
    }
    
    public func from(_ db: String) -> Self {
        froms.append("\"\(db)\"")
        return self
    }
    
    public func from<T>(_ db: T.Type) -> Self where T: Model {
        froms.append(T.FQType.query)
        return self
    }
    
    public func from<T>(_ db: FQAlias<T>) -> Self {
        froms.append(db.query)
        return self
    }
    
    public func from(raw: String) -> Self {
        froms.append(raw)
        return self
    }
    
    public func join<T>(_ mode: FQJoinMode, _ table: T.Type, where: FQWhere) -> Self where T: Model {
        joins.append(FQJoin(mode, table: T.FQType.self, where: `where`))
        return self
    }
    
    public func join<T>(_ mode: FQJoinMode, _ table: FQAlias<T>, where: FQWhere) -> Self where T: Model {
        joins.append(FQJoin(mode, table: table, where: `where`))
        return self
    }
    
    @discardableResult
    public func `where`(_ where: FQWhere) -> Self {
        self.`where` = `where`
        return self
    }
    
    @discardableResult
    public func having(_ where: FQWhere) -> Self {
        having = `where`
        return self
    }
    
    @discardableResult
    public func groupBy(_ groupBy: FQGroupBy) -> Self {
        self.groupBy = groupBy
        return self
    }
    
    @discardableResult
    public func orderBy(_ orderBy: FQOrderBy) -> Self {
        self.orderBy = orderBy
        return self
    }
    
    @discardableResult
    public func offset(_ v: Int) -> Self {
        self.offset = v
        return self
    }
    
    @discardableResult
    public func limit(_ v: Int) -> Self {
        self.limit = v
        return self
    }
    
    public var query: String {
        var result = "SELECT"
        for (index, field) in selectFields.enumerated() {
            if index > 0 {
                result.append(",")
            }
            result.append(FluentQueryNextLine)
            result.append(field.query)
        }
        if froms.count > 0 {
            result.append(FluentQueryNextLine)
            result.append("FROM")
            for (index, from) in froms.enumerated() {
                if index > 0 {
                    result.append(",")
                }
                result.append(FluentQueryNextLine)
                result.append(from.query)
            }
        }
        for join in joins {
            result.append(FluentQueryNextLine)
            result.append(join.query)
        }
        if let w = `where` {
            result.append(FluentQueryNextLine)
            result.append("WHERE")
            result.append(FluentQueryNextLine)
            result.append(w.query)
        }
        if let groupBy = groupBy {
            result.append(FluentQueryNextLine)
            result.append("GROUP BY")
            result.append(FluentQueryNextLine)
            result.append(groupBy.query)
        }
        if let having = having {
            result.append(FluentQueryNextLine)
            result.append("HAVING")
            result.append(FluentQueryNextLine)
            result.append(having.query)
        }
        if let orderBy = orderBy {
            result.append(FluentQueryNextLine)
            result.append("ORDER BY")
            result.append(FluentQueryNextLine)
            result.append(orderBy.query)
        }
        if let offset = offset {
            result.append(FluentQueryNextLine)
            result.append("OFFSET \(offset)")
        }
        if let limit = limit {
            result.append(FluentQueryNextLine)
            result.append("LIMIT \(limit)")
        }
        return result
    }
    
    public func build() -> String {
        return query
    }
}

extension FluentQuery {
    static func formattedPath<T, V>(_ table: FQTable<T>.Type, _ kp: KeyPath<T, V>) -> String where T: Model {
        return FluentQuery.formattedPath(table.alias, kp)
    }
    
    static func formattedPath<T, V>(_ table: String, _ kp: KeyPath<T, V>) -> String where T: Model {
        var formattedPath = ""
        let values: [String] = T.describeKeyPath(kp)
        for (index, p) in values.enumerated() {
            if index == 0 {
                formattedPath.append("\"\(p)\"")
            } else {
                formattedPath.append("->")
                formattedPath.append("'\(p)'")
            }
        }
        return "\"\(table)\".\(formattedPath)"
    }
}

extension Model {
    typealias FQType = FQTable<Self>
    
    static func describeKeyPath<V>(_ kp: KeyPath<Self, V>) -> [String] {
        if let pathParts = try? Self.reflectProperty(forKey: kp)?.path {
            return pathParts ?? []
        }
        return []
    }
    
    static func property<T, V>(_ kp: KeyPath<T, V>) -> String where T: Model {
        return FluentQuery.formattedPath(T.FQType.self, kp)
    }
}

let FluentQueryNextLine = """


"""
