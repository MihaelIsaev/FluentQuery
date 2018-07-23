import Foundation
import Fluent
import Crypto

extension Model {
    /// Helper method for generating random string
    private static func shuffledAlphabet(_ length: Int) -> String {
        let letters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var randomString = ""
        for _ in 0...length - 1 {
            if let random = try? CryptoRandom().generate(UInt32.self) {
                let rand = random % UInt32(letters.count)
                let ind = Int(rand)
                let character = letters[letters.index(letters.startIndex, offsetBy: ind)]
                randomString.append(character)
            }
        }
        return randomString
    }
    
    /// It will return alias named: Model.name + randomString
    /// it will return new alias every time you call it
    public static var randomAlias: FQAlias<Self> {
        return alias(shuffledAlphabet(3))
    }
    
    /// It will return alias named: Model.name + number
    public static func alias(_ number: Int) -> FQAlias<Self> {
        return alias("\(number)")
    }
    
    /// It will return alias named: Model.name + "Alias"
    public static var alias: FQAlias<Self> {
        return alias()
    }
    
    /// By default it will return alias named: Model.name + "Alias"
    /// as .alias lazy property
    /// or you can provide your own string
    /// and it will return alias named: Model.name + yourString
    /// If you want to set your own short alias please use `alias(short:)` method
    public static func alias(_ additionalString: String? = nil) -> FQAlias<Self> {
        return FQAlias<Self>(entity + (additionalString ?? "Alias"))
    }
    
    /// It will return alias named: your own string
    public static func alias(short: String) -> FQAlias<Self> {
        return FQAlias<Self>(short)
    }
}

public class AliasedKeyPath<M, V>: FQPart where M: Model {
    var alias: String
    var kp: KeyPath<M, V>
    init(_ alias: String, _ kp: KeyPath<M, V>) {
        self.alias = alias
        self.kp = kp
    }
    
    public var query: String {
        return FluentQuery.formattedPath(alias, kp)
    }
}

public class FQAlias<M>: FQPart where M: Model {
    var name: String {
        return M.entity
    }
    var alias: String
    
    public init(_ alias: String) {
        self.alias = alias
    }
    
    //MARK: SQLQueryPart
    
    public var query: String {
        return name.doubleQuotted.as(alias.doubleQuotted)
    }
    
    public func k<V>(_ kp: KeyPath<M, V>) -> AliasedKeyPath<M, V> {
        return AliasedKeyPath(alias, kp)
    }
}

public protocol FQUniversalKeyPathSimple {
    var queryValue: String { get }
}

public protocol FQUniversalKeyPath {
    associatedtype AType
    associatedtype AModel: Model
    associatedtype ARoot
    
    var queryValue: String { get }
    var originalKeyPath: KeyPath<AModel, AType> { get }
}

extension KeyPath: FQUniversalKeyPath, FQUniversalKeyPathSimple  where Root: Model {
    public typealias AType = Value
    public typealias AModel = Root
    public typealias ARoot = KeyPath
    
    public var queryValue: String {
        return FQGetKeyPath(self)
    }
    
    public var originalKeyPath: KeyPath<Root, Value> {
        return self
    }
}

extension AliasedKeyPath: FQUniversalKeyPath, FQUniversalKeyPathSimple {
    public typealias AType = V
    public typealias AModel = M
    public typealias ARoot = AliasedKeyPath
    
    public var queryValue: String {
        return FQGetKeyPath(self)
    }
    
    public var originalKeyPath: KeyPath<M, V> {
        return kp
    }
}

public protocol FQUniversalModel {
    var queryValue: String { get }
}
