import Foundation
import Fluent

public class FQGroupBy: FQPart {
    var parts: [FQPart] = []
    
    public init () {}
    
    public init<T>(_ kp: T) where T: FQUniversalKeyPath {
        add(kp)
    }
    
    @discardableResult
    public func add<T>(_ kp: T) -> Self where T: FQUniversalKeyPath {
        parts.append(kp.queryValue)
        return self
    }
    
    @discardableResult
    public func and<T>(_ kp: T) -> Self where T: FQUniversalKeyPath {
        return add(kp)
    }
    
    public var query: String {
        return parts.map { $0.query }.joined(separator: ", ")
    }
}
