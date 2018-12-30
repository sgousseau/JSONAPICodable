import Foundation

public typealias JSON = [String: Any]

public protocol JSONAPICodable: Codable {
    var id: String { get set }
    var type: String { get set }
}

public protocol JSONAPIAttributeExpressible: Codable {}

extension String: JSONAPIAttributeExpressible {}

public protocol JSONAPIPrimitive {}

extension String: JSONAPIPrimitive {}
extension Int: JSONAPIPrimitive {}
extension Double: JSONAPIPrimitive {}
extension Float: JSONAPIPrimitive {}
extension Bool: JSONAPIPrimitive {}

extension Optional: JSONAPIPrimitive where Wrapped == JSONAPIPrimitive {}

protocol OptionalProtocol {
    func isSome() -> Bool
    func unwrap() -> Any
}

extension Optional : OptionalProtocol {
    func isSome() -> Bool {
        switch self {
        case .none: return false
        case .some: return true
        }
    }
    
    func unwrap() -> Any {
        switch self {
        case .none: preconditionFailure("nil unwrap")
        case .some(let unwrapped): return unwrapped
        }
    }
}
