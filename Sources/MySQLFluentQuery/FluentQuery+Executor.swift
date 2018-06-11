import FluentMySQL
@_exported import FluentQuery

extension FluentQuery {
    public func execute<D>(on conn: D, _ parameters: [MySQLDataConvertible] = []) -> Future<[[MySQLColumn : MySQLData]]> where D: MySQLConnection {
        return conn.query(self.query, parameters)
    }
    
    public func execute<D, T>(on conn: D, _ parameters: [MySQLDataConvertible] = [], andDecode to: T.Type, withDateDecodingStrategy strategy: JSONDecoder.DateDecodingStrategy? = nil)throws -> Future<[T]>
        where D: MySQLConnection, T: Decodable {
            return try conn.query(self.query, parameters).decode(T.self, dateDecodingStrategy: strategy)
    }
    
    public func execute<D, T>(on conn: D, _ parameters: [MySQLDataConvertible] = [], andDecode to: [T].Type, withDateDecodingStrategy strategy: JSONDecoder.DateDecodingStrategy? = nil)throws -> Future<[T]>
        where D: MySQLConnection, T: Decodable {
            return try conn.query(self.query, parameters).decode(T.self, dateDecodingStrategy: strategy)
    }
}
