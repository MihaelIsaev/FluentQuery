import FluentMySQL
import FluentQuery
import Foundation

extension EventLoopFuture where T == [[MySQLColumn : MySQLData]] {
    public func decode<T>(_ to: T.Type) throws -> EventLoopFuture<[T]> where T: Decodable {
        return map { return try $0.decode(T.self) }
    }
}

extension Array where Element == [MySQLColumn : MySQLData] {
    public func decode<T>(_ to: T.Type) throws -> [T] where T: Decodable {
        return try map { try $0.decode(T.self) }
    }
}

extension Dictionary where Key == MySQL.MySQLColumn, Value == MySQL.MySQLData {
    public func decode<T>(_ to: [T.Type]) throws -> T where T: Decodable {
        return try decode(T.self)
    }
    
    public func decode<T>(_ to: T.Type) throws -> T where T: Decodable {
        let convertedRowValues = map { (QueryField(name: $0.name), $1) }
        let convertedRow = Dictionary<QueryField, MySQL.MySQLData>(uniqueKeysWithValues: convertedRowValues)
        return try FQDataDecoder(MySQLDatabase.self, entity: nil, dateDecodingStrategy: nil).decode(to, from: convertedRow)
    }
}

extension MySQLData: JSONFieldSupporting {
    public var json: Data? {
        guard self.type == .MYSQL_TYPE_JSON else { return nil }
        return self.data()
    }
}
