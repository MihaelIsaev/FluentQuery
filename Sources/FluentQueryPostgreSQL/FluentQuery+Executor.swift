import FluentPostgreSQL
@_exported import FluentQuery

extension FluentQuery {
    public func execute<D>(on conn: D) -> Future<[[PostgreSQL.PostgreSQLColumn: PostgreSQLData]]> where D: PostgreSQLConnection {
        return conn.query(query)
    }
    
    public func execute<D, T>(on conn: D, andDecode to: T.Type, withDateDecodingStrategy strategy: JSONDecoder.DateDecodingStrategy? = nil) throws -> Future<[T]> where D: PostgreSQLConnection, T: Decodable {
        return try execute(on: conn).decode(T.self, dateDecodingStrategy: strategy)
    }
    
    public func execute<D, T>(on conn: D, andDecode to: [T].Type, withDateDecodingStrategy strategy: JSONDecoder.DateDecodingStrategy? = nil) throws -> Future<[T]> where D: PostgreSQLConnection, T: Decodable {
        return try execute(on: conn).decode(T.self, dateDecodingStrategy: strategy)
    }
}
