import Foundation

public final class JSONAPIEncoder {
    
    enum IdEncodingStrategy {
        case emptyId
        case randomId
    }
    
    private var encodingStrategy: IdEncodingStrategy = .randomId
    
    public init() {}
    
    public func encode<T: Encodable>(_ object: T) throws -> Data {
        return try JSONSerialization.data(withJSONObject: try jsonapi(object), options: .prettyPrinted)
    }
    
    private func jsonapi<T: Encodable>(_ object: T) throws -> JSON { //json can be either an object or an array
        let objectData = try JSONEncoder().encode(object)
        let jsonObject = try JSONSerialization.jsonObject(with: objectData, options: .allowFragments)
        
        if let optional = jsonObject as? OptionalProtocol, !optional.isSome() {
            throw JSONAPIError.notJsonApiCompatible(object: object)
        }
        
//        #if DEBUG
//        print("JSON")
//        print(String(data: try! JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted), encoding: .utf8)!)
//        #endif
        
        var result = JSON()
        var included = JSON()
        
        if let array = jsonObject as? [JSON] {
            if let badRoot = array.first(where: { $0.identifier == nil }) {
                throw JSONAPIError.badRoot(json: badRoot)
            }
            
            result["data"] = array.map({ buildJSONAPIObject(standardJson: $0, included: &included)}).compactMap({ $0 })
            
            filterIncluded(removingKeys: array.map({ $0.identifier! }), included: &included)
            
        } else if let json = jsonObject as? JSON, let build = buildJSONAPIObject(standardJson: json, included: &included) {
            if json.identifier == nil {
                throw JSONAPIError.badRoot(json: json)
            }
            
            result["data"] = build
            filterIncluded(removingKeys: [json.identifier!], included: &included)
        } else {
            throw JSONAPIError.notJsonApiCompatible(object: object)
        }
        
        
        if !included.isEmpty {
            result["included"] = included.map({ $0.value })
        }
        
        return result
    }
    
    private func buildJSONAPIObject(standardJson: JSON, included: inout JSON) -> JSON? {
        var result = JSON()
        
        if let attributes = buildJSONAPIAttributes(standardJson: standardJson) {
            result.merge(attributes, uniquingKeysWith: uniquingByLast)
        }
        
        if let relationships = buildJSONAPIRelations(standardJson: standardJson, included: &included) {
            result.merge(relationships, uniquingKeysWith: uniquingByLast)
        }
        
        if standardJson.meta != nil {
            result["meta"] = standardJson.meta!
        }
        
        if standardJson.links != nil {
            result["links"] = standardJson.links!
        }
        
        if let identifiers = standardJson.identifiers {
            result.merge(identifiers, uniquingKeysWith: uniquingByLast)
            included.merge([standardJson.identifier!: result], uniquingKeysWith: uniquingByLast)
        }
        
        return result
    }
    
    private func buildJSONAPIAttributes(standardJson: JSON) -> JSON? {
        var result = JSON()
        for (key, val) in standardJson.withoutIdentifiers {
            if key == "meta" || key == "links" || key == "relationships" || key == "attributes" {
                continue
            }
            
            if let _ = val as? JSONAPIAttributeExpressible {
                result[key] = val
            } else if let _ = val as? [JSONAPIAttributeExpressible] {
                result[key] = val
            } else if let json = val as? JSON, json.isJSONAPIAttributeExpressible {
                result[key] = json
            } else if let jsons = val as? [JSON], jsons.map({ $0.isJSONAPIAttributeExpressible }).reduce(true, { $0 && $1 }) {
                result[key] = jsons
            } else if let _ = val as? JSON {
                continue
            } else if let _ = val as? [JSON] {
                continue
            } else {
                result[key] = val
            }
        }
        
        return result.isEmpty ? nil : ["attributes": result]
    }
    
    private func buildJSONAPIRelations(standardJson: JSON, included: inout JSON) -> JSON? {
        var result = JSON()
        for (key, val) in standardJson.withoutIdentifiers {
            if key == "meta" || key == "links" || key == "relationships" || key == "attributes" {
                continue
            }
            
            if let _ = val as? JSONAPIAttributeExpressible {
                continue
            } else if let _ = val as? [JSONAPIAttributeExpressible] {
                continue
            } else if let json = val as? JSON, json.isJSONAPIAttributeExpressible {
                continue
            } else if let jsons = val as? [JSON], jsons.map({ $0.isJSONAPIAttributeExpressible }).reduce(true, { $0 && $1 }) {
                continue
            } else if let json = val as? JSON {
                result[key] = ["data": json.identifiers]
                
                _ = buildJSONAPIObject(standardJson: json, included: &included)
                
            } else if let jsons = val as? [JSON], jsons.map({ $0.isJSONAPIRelationExpressible }).reduce(true, { $0 && $1 }) {
                result[key] = ["data": jsons.map({ $0.identifiers })]
                
                _ = jsons.map({ buildJSONAPIObject(standardJson: $0, included: &included) })
            }
        }
        
        return result.isEmpty ? nil : ["relationships": result]
    }
    
    private func filterIncluded(removingKeys: [String], included: inout JSON) {
        removingKeys.forEach({ included.removeValue(forKey: $0) })
    }
    
    private func uniquingByLast(first: Any, last: Any) -> Any {
        return last
    }
    
    private func uniquingByFirst(first: Any, last: Any) -> Any {
        return first
    }
}

extension Dictionary where Key == String, Value == Any {
    
    var id: String? {
        return self["id"] as? String
    }
    
    var type: String? {
        return self["type"] as? String
    }
    
    var identifiers: [Key: Value]? {
        return id != nil && type != nil ? ["id": id!, "type": type!] : nil
    }
    
    var identifier: String? {
        return id != nil && type != nil ? "\(id!):\(type!)" : nil
    }
    
    var withoutIdentifiers: [Key: Value] {
        var result = self
        result.removeValue(forKey: "id")
        result.removeValue(forKey: "type")
        return result
    }
    
    var attributes: [Key: Value]? {
        return self["attributes"] as? [String: Any]
    }
    
    var relationships: [Key: Value]? {
        return self["relationships"] as? [String: Any]
    }
    
    var meta: [Key: Value]? {
        return self["meta"] as? [String: Any]
    }
    
    var links: [Key: Value]? {
        return self["links"] as? [String: Any]
    }
    
    var included: [[Key: Value]]? {
        return self["included"] as? [[String: Any]]
    }
    
    var child: [Key: Value]? {
        return self["data"] as? [String: Any]
    }
    
    var children: [[Key: Value]]? {
        return self["data"] as? [[String: Any]]
    }
    
    var isJSONAPIAttributeExpressible: Bool {
        return id == nil || id!.isEmpty || type == nil || type!.isEmpty
    }
    
    var isJSONAPIRelationExpressible: Bool {
        return !isJSONAPIAttributeExpressible
    }
}

extension Encodable {
    var jsonapi: [String: Any]? {
        guard let data = try? JSONAPIEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
    
    var json: Any? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}

//extension Sequence where Iterator.Element: Encodable {
//    var jsonArray: [[String: Any]]? {
//        return reduce([], { collection, element in collection + [element.json] }).compactMap({ $0 }) as? [[String: Any]]
//    }
//}

extension Dictionary {
    subscript(nestedObjectAt key: Key) -> [String: Any]? {
        get {
            return self[key] as? [String: Any]
        }
        set {
            self[key] = newValue as? Value
        }
    }
    
    subscript(nestedArrayAt key: Key) -> [[String: Any]]? {
        get {
            return self[key] as? [[String: Any]]
        }
        set {
            self[key] = newValue as? Value
        }
    }
}

//extension Sequence where Iterator.Element: Equatable {
//    func unique() -> [Iterator.Element] {
//        return reduce([], { collection, element in collection.contains(element) ? collection : collection + [element] })
//    }
//}
