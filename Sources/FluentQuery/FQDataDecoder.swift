import Foundation
import FluentPostgreSQL
import PostgreSQL

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

// Renamed decoder from Fluent repo
// copied it just to make it public to start using it
// will remove it when Fluent will make it public

public final class FQDataDecoder<Database> where Database: QuerySupporting {
    var entity: String?
    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?
    public init(_ database: Database.Type, entity: String? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) {
        self.entity = entity
        self.dateDecodingStrategy = dateDecodingStrategy
    }
    public func decode<D>(_ type: D.Type, from data: [QueryField: Database.QueryData]) throws -> D where D: Decodable {
        let decoder = _QueryDataDecoder<Database>(data: data, entity: entity, dateDecodingStrategy: dateDecodingStrategy)
        return try D.init(from: decoder)
    }
}

/// MARK: Private

fileprivate final class _QueryDataDecoder<Database>: Decoder where Database: QuerySupporting {
    var codingPath: [CodingKey] { return [] }
    var userInfo: [CodingUserInfoKey: Any] { return [:] }
    var data: [QueryField: Database.QueryData]
    var entity: String?
    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?
    init(data: [QueryField: Database.QueryData], entity: String?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) {
        self.data = data
        self.entity = entity
        self.dateDecodingStrategy = dateDecodingStrategy
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(_QueryDataKeyedDecoder<Key, Database>(decoder: self, entity: entity, dateDecodingStrategy: dateDecodingStrategy))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer { throw unsupported() }
    func singleValueContainer() throws -> SingleValueDecodingContainer { throw unsupported() }
}

private func unsupported() -> FluentError {
    return FluentError(
        identifier: "rowDecode",
        reason: "PostgreSQL rows only support a flat, keyed structure `[String: T]`",
        suggestedFixes: [
            "You can conform nested types to `PostgreSQLJSONType` or `PostgreSQLArrayType`. (Nested types must be `PostgreSQLDataCustomConvertible`.)"
        ],
        source: .capture()
    )
}


fileprivate struct _QueryDataKeyedDecoder<K, Database>: KeyedDecodingContainerProtocol
    where K: CodingKey, Database: QuerySupporting
{
    var allKeys: [K] {
        return decoder.data.keys.compactMap { K(stringValue: $0.name) }
    }
    var codingPath: [CodingKey] { return [] }
    let decoder: _QueryDataDecoder<Database>
    var entity: String?
    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
    init(decoder: _QueryDataDecoder<Database>, entity: String?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) {
        self.decoder = decoder
        self.entity = entity
        if let dateDecodingStrategy = dateDecodingStrategy {
            self.dateDecodingStrategy = dateDecodingStrategy
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            self.dateDecodingStrategy = .formatted(formatter)
        }
    }
    
    func _value(forEntity entity: String?, atField field: String) -> Database.QueryData? {
        guard let entity = entity else {
            return decoder.data.firstValue(forField: field)
        }
        return decoder.data.value(forEntity: entity, atField: field) ?? decoder.data.firstValue(forField: field)
    }
    
    func _parse<T>(_ type: T.Type, forKey key: K) throws -> T? where T: Decodable {
        guard let data = _value(forEntity: entity, atField: key.stringValue)  else {
            return nil
        }
        if let data = data as? PostgreSQLData {
            if type is Decodable.Type {
                if let data = data.data {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = dateDecodingStrategy
                    return try? decoder.decode(T.self, from: data[1...])
                } else {
                    return nil
                }
            } else {
                throw FluentError(identifier: "decodingError", reason: "\(type) should conform to Decodable protocol", source: .capture())
            }
        }
        return try Database.queryDataParse(T.self, from: data)
    }
    
    func contains(_ key: K) -> Bool { return decoder.data.keys.contains { $0.name == key.stringValue } }
    func decodeNil(forKey key: K) throws -> Bool { return _value(forEntity: entity, atField: key.stringValue) == nil }
    func decodeIfPresent(_ type: Int.Type, forKey key: K) throws -> Int? { return try _parse(Int.self, forKey: key) }
    func decodeIfPresent(_ type: Int8.Type, forKey key: K) throws -> Int8? { return try _parse(Int8.self, forKey: key) }
    func decodeIfPresent(_ type: Int16.Type, forKey key: K) throws -> Int16? { return try _parse(Int16.self, forKey: key) }
    func decodeIfPresent(_ type: Int32.Type, forKey key: K) throws -> Int32? { return try _parse(Int32.self, forKey: key) }
    func decodeIfPresent(_ type: Int64.Type, forKey key: K) throws -> Int64? { return try _parse(Int64.self, forKey: key) }
    func decodeIfPresent(_ type: UInt.Type, forKey key: K) throws -> UInt? {  return try _parse(UInt.self, forKey: key) }
    func decodeIfPresent(_ type: UInt8.Type, forKey key: K) throws -> UInt8? { return try _parse(UInt8.self, forKey: key) }
    func decodeIfPresent(_ type: UInt16.Type, forKey key: K) throws -> UInt16? { return try _parse(UInt16.self, forKey: key) }
    func decodeIfPresent(_ type: UInt32.Type, forKey key: K) throws -> UInt32? { return try _parse(UInt32.self, forKey: key) }
    func decodeIfPresent(_ type: UInt64.Type, forKey key: K) throws -> UInt64? { return try _parse(UInt64.self, forKey: key) }
    func decodeIfPresent(_ type: Double.Type, forKey key: K) throws -> Double? { return try _parse(Double.self, forKey: key) }
    func decodeIfPresent(_ type: Float.Type, forKey key: K) throws -> Float? { return try _parse(Float.self, forKey: key) }
    func decodeIfPresent(_ type: Bool.Type, forKey key: K) throws -> Bool? { return try _parse(Bool.self, forKey: key) }
    func decodeIfPresent(_ type: String.Type, forKey key: K) throws -> String? { return try _parse(String.self, forKey: key) }
    func decodeIfPresent<T>(_ type: T.Type, forKey key: K) throws -> T? where T: Decodable { return try _parse(T.self, forKey: key) }
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        guard let t = try _parse(T.self, forKey: key) else {
            throw FluentError(identifier: "missingValue", reason: "No value found for key: \(key)", source: .capture())
        }
        return t
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey>
        where NestedKey : CodingKey { return try decoder.container(keyedBy: NestedKey.self) }
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer { return try decoder.unkeyedContainer() }
    func superDecoder() throws -> Decoder { return decoder }
    func superDecoder(forKey key: K) throws -> Decoder { return decoder }
}


