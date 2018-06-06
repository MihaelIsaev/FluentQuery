import Foundation
import FluentPostgreSQL
import Fluent
import PostgreSQL

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
    public var select: FQSelect = FQSelect()
    public var froms: [FQPart] = []
    public var joins: [FQJoinGenericType] = []
    public var `where`: FQWhere?
    public var groupBy: FQGroupBy?
    public var having: FQWhere?
    public var orderBy: FQOrderBy?
    public var offset: Int?
    public var limit: Int?
    
    public init() {}
    
    public func select(_ select: FQSelect) {
        self.select.joinAnotherInstance(select)
    }
    
    @available(*, deprecated: 1.0, message: "will soon become unavailable.")
    public func select(_ str: String) -> Self {
        select.field(str)
        return self
    }
    
    public func select<T>(all: T.Type) -> Self where T: Model {
        select.all(all)
        return self
    }
    
    public func select<T>(_ kp: T, as: String? = nil) -> Self where T: FQUniversalKeyPath {
        select.field(kp)
        return self
    }
    
    public func select<T>(distinct kp: T, as: String? = nil) -> Self where T: FQUniversalKeyPath {
        select.distinct(kp, as: `as`)
        return self
    }
    
    public func select<T>(count kp: T, as: String? = nil) -> Self where T: FQUniversalKeyPath{
        select.func(.count(kp), path: kp, as: `as`) //TODO
        return self
    }
    
    public func select(as: String? = nil, _ json: FQJSON) -> Self {
        select.field(as: `as`, json)
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
        result.append(FluentQueryNextLine)
        result.append(select.query)
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
    
    public func execute<D>(on conn: D) -> Future<[[PostgreSQL.PostgreSQLColumn: PostgreSQLData]]> where D: PostgreSQLConnection {
        return conn.query(query)
    }
    
    public func execute<D, T>(on conn: D, andDecode to: T.Type) throws -> Future<[T]> where D: PostgreSQLConnection, T: Decodable {
        return try execute(on: conn).decode(T.self)
    }
    
    public func execute<D, T>(on conn: D, andDecode to: [T].Type) throws -> Future<[T]> where D: PostgreSQLConnection, T: Decodable {
        return try execute(on: conn).decode(T.self)
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

public func FQGetKeyPath<T, V>(_ kp: KeyPath<T, V>) -> String where T: Model {
    return FluentQuery.formattedPath(T.FQType.self, kp)
}

public func FQGetKeyPath<T, V>(_ alias: AliasedKeyPath<T, V>) -> String where T: Model {
    return alias.query
}
