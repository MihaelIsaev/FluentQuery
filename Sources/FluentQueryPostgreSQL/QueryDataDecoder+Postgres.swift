import FluentPostgreSQL
import FluentQuery

extension EventLoopFuture where T == [[PostgreSQL.PostgreSQLColumn: PostgreSQLData]] {
    public func decode<T>(_ to: T.Type, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) throws -> EventLoopFuture<[T]> where T: Decodable {
        return map { return try $0.decode(T.self, dateDecodingStrategy: dateDecodingStrategy) }
    }
}

extension Array where Element == [PostgreSQL.PostgreSQLColumn: PostgreSQL.PostgreSQLData] {
    public func decode<T>(_ to: T.Type, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) throws -> [T] where T: Decodable {
        return try map { try $0.decode(T.self, dateDecodingStrategy: dateDecodingStrategy) }
    }
}

extension Dictionary where Key == PostgreSQL.PostgreSQLColumn, Value == PostgreSQL.PostgreSQLData {
    public func decode<T>(_ to: [T.Type], dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) throws -> T where T: Decodable {
        return try decode(T.self, dateDecodingStrategy: dateDecodingStrategy)
    }
    
    public func decode<T>(_ to: T.Type, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) throws -> T where T: Decodable {
        let convertedRowValues = map { (QueryField(name: $0.name), $1) }
        let convertedRow = Dictionary<QueryField, PostgreSQL.PostgreSQLData>(uniqueKeysWithValues: convertedRowValues)
        return try FQDataDecoder(PostgreSQLDatabase.self, entity: nil, dateDecodingStrategy: dateDecodingStrategy).decode(to, from: convertedRow)
    }
}

extension PostgreSQLData: JSONFieldSupporting {
    public var json: Data? {
        guard self.type == .jsonb || self.type == ._jsonb || self.type == .json else { return nil }
        return self.data
    }
}
