import FluentMySQL
@_exported import FluentQuery

extension FluentQuery {
    public func execute<D>(on conn: D) -> Future<[[MySQLColumn : MySQLData]]> where D: MySQLConnection {
        return conn.query(self.query, [])
    }
    
    public func execute<D, T>(on conn: D, andDecode to: T.Type)throws -> Future<[T]>
        where D: MySQLConnection, T: Decodable {
            return try conn.query(self.query, []).decode(T.self)
    }
    
    public func execute<D, T>(on conn: D, andDecode to: [T].Type)throws -> Future<[T]>
        where D: MySQLConnection, T: Decodable {
            return try conn.query(self.query, []).decode(T.self)
    }
}
