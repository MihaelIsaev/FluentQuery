import Foundation
import Fluent

public class FQOrderBy: FQPart {
    public enum Mode: String {
        case descending = "DESC"
        case ascending = "ASC"
    }
    
    public struct Data: FQPart {
        var path: String
        var mode: Mode
        
        public init<T>(_ kp: T, _ mode: Mode) where T: FQUniversalKeyPath {
            self.path = kp.queryValue
            self.mode = mode
        }
        
        public var query: String {
            return "\(path) \(mode.rawValue)"
        }
    }
    
    var parts: [Data] = []
    
    public init(copy from: FQOrderBy? = nil) {
        if let from = from {
            parts = from.parts.map { $0 }
        }
    }
    
    public init<T>(_ kp: T, _ mode: Mode) where T: FQUniversalKeyPath {
        add(kp, mode)
    }
    
    @discardableResult
    public func add<T>(_ kp: T, _ mode: Mode) -> Self where T: FQUniversalKeyPath {
        parts.append(Data(kp, mode))
        return self
    }
    
    @discardableResult
    public func and<T>(_ kp: T, _ mode: Mode) -> Self where T: FQUniversalKeyPath {
        return add(kp, mode)
    }
    
    public var query: String {
        return parts.map { $0.query }.joined(separator: ", ")
    }
    
    public func joinAnotherInstance(_ inst: FQOrderBy) {
        if inst.parts.count > 0 {
            parts.append(contentsOf: inst.parts)
        }
    }
}

