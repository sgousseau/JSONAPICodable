import Foundation

public protocol JSONAPIAttributeExpressible: Codable {}

private protocol JSONAPIOptional {
    func isSome() -> Bool
    func unwrap() -> Any
}

extension Optional : JSONAPIOptional {
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

public enum JSONAPIIdEncodingStrategy {
    case withoutId
    case withRandomId
    case withId
}

public final class JSONAPIEncoder {
    
    public init() {}
    
    private var encodingStrategy: JSONAPIIdEncodingStrategy = .withRandomId
    
    public func encode<T: Encodable>(_ object: T, encoding strategy: JSONAPIIdEncodingStrategy = .withRandomId) throws -> Data {
        return try JSONSerialization.data(withJSONObject: try jsonapi(object, encoding: strategy), options: .prettyPrinted)
    }
    
    private func jsonapi<T: Encodable>(_ object: T, encoding strategy: JSONAPIIdEncodingStrategy = .withRandomId) throws -> [String: Any] {
        
        let objectData = try JSONEncoder().encode(object)
        let jsonObject = try JSONSerialization.jsonObject(with: objectData, options: .allowFragments)
        
        if let optional = jsonObject as? JSONAPIOptional, !optional.isSome() {
            throw JSONAPIError.notJsonApiCompatible(object: object)
        }
        
        var result = [String: Any]()
        var included = [String: Any]()
        
        if let array = jsonObject as? [[String: Any]] {
            if let badRoot = array.first(where: { $0.identifier == nil }) {
                throw JSONAPIError.badRoot(json: badRoot)
            }
            
            result[JSONAPIKeys.data.rawValue] = array.map({ buildJSONAPIObject(standardJson: $0, included: &included)}).compactMap({ $0 })
            
            filterIncluded(removingKeys: array.map({ $0.identifier! }), included: &included)
            
        } else if let json = jsonObject as? [String: Any], let build = buildJSONAPIObject(standardJson: json, included: &included) {
            if json.identifier == nil {
                throw JSONAPIError.badRoot(json: json)
            }
            
            result[JSONAPIKeys.data.rawValue] = build
            filterIncluded(removingKeys: [json.identifier!], included: &included)
        } else {
            throw JSONAPIError.notJsonApiCompatible(object: object)
        }
        
        if !included.isEmpty {
            result[JSONAPIKeys.included.rawValue] = included.map({ $0.value })
        }
        
        return result
    }
    
    private func buildJSONAPIObject(standardJson: [String: Any], included: inout [String: Any]) -> [String: Any]? {
        var result = [String: Any]()
        
        if let attributes = buildJSONAPIAttributes(standardJson: standardJson) {
            result.merge(attributes, uniquingKeysWith: uniquingByLast)
        }
        
        if let relationships = buildJSONAPIRelations(standardJson: standardJson, included: &included) {
            result.merge(relationships, uniquingKeysWith: uniquingByLast)
        }
        
        if standardJson.meta != nil {
            result[JSONAPIKeys.meta.rawValue] = standardJson.meta!
        }
        
        if standardJson.links != nil {
            result[JSONAPIKeys.links.rawValue] = standardJson.links!
        }
        
        if let identifiers = standardJson.identifiers {
            result.merge(identifiers, uniquingKeysWith: uniquingByLast)
            included.merge([standardJson.identifier!: result], uniquingKeysWith: uniquingByLast)
        }
        
        return result
    }
    
    private func buildJSONAPIAttributes(standardJson: [String: Any]) -> [String: Any]? {
        var result = [String: Any]()
        for (key, val) in standardJson.withoutIdentifiers {
            if key == JSONAPIKeys.meta.rawValue || key == JSONAPIKeys.links.rawValue || key == JSONAPIKeys.relationships.rawValue || key == JSONAPIKeys.attributes.rawValue {
                continue
            }
            
            if let _ = val as? JSONAPIAttributeExpressible {
                result[key] = val
            } else if let _ = val as? [JSONAPIAttributeExpressible] {
                result[key] = val
            } else if let json = val as? [String: Any], json.isJSONAPIAttributeExpressible {
                result[key] = json
            } else if let jsons = val as? [[String: Any]], jsons.map({ $0.isJSONAPIAttributeExpressible }).reduce(true, { $0 && $1 }) {
                result[key] = jsons
            } else if let _ = val as? [String: Any] {
                continue
            } else if let _ = val as? [[String: Any]] {
                continue
            } else {
                result[key] = val
            }
        }
        
        return result.isEmpty ? nil : [JSONAPIKeys.attributes.rawValue: result]
    }
    
    private func buildJSONAPIRelations(standardJson: [String: Any], included: inout [String: Any]) -> [String: Any]? {
        var result = [String: Any]()
        for (key, val) in standardJson.withoutIdentifiers {
            if key == JSONAPIKeys.meta.rawValue || key == JSONAPIKeys.links.rawValue || key == JSONAPIKeys.relationships.rawValue || key == JSONAPIKeys.attributes.rawValue {
                continue
            }
            
            if let _ = val as? JSONAPIAttributeExpressible {
                continue
            } else if let _ = val as? [JSONAPIAttributeExpressible] {
                continue
            } else if let json = val as? [String: Any], json.isJSONAPIAttributeExpressible {
                continue
            } else if let jsons = val as? [[String: Any]], jsons.map({ $0.isJSONAPIAttributeExpressible }).reduce(true, { $0 && $1 }) {
                continue
            } else if let json = val as? [String: Any] {
                result[key] = [JSONAPIKeys.data.rawValue: json.identifiers]
                
                _ = buildJSONAPIObject(standardJson: json, included: &included)
                
            } else if let jsons = val as? [[String: Any]], jsons.map({ $0.isJSONAPIRelationExpressible }).reduce(true, { $0 && $1 }) {
                result[key] = [JSONAPIKeys.data.rawValue: jsons.map({ $0.identifiers })]
                
                _ = jsons.map({ buildJSONAPIObject(standardJson: $0, included: &included) })
            }
        }
        
        return result.isEmpty ? nil : [JSONAPIKeys.relationships.rawValue: result]
    }
    
    private func filterIncluded(removingKeys: [String], included: inout [String: Any]) {
        removingKeys.forEach({ included.removeValue(forKey: $0) })
    }
}

