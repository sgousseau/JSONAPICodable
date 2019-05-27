import Foundation

public enum DecodingOption {
    case rootLevelLinksOverride
    case objectLevelLinksOverride
}


public final class JSONAPIDecoder {
    
    public init() {}
    
    private var decodingOption: DecodingOption!
    
    public func decode<T>(_ type: T.Type, from data: Data, option: DecodingOption = .rootLevelLinksOverride) throws -> T where T: Decodable {
        
        self.decodingOption = option
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
            let dataObject = jsonObject?[JSONAPIKeys.data.rawValue]
            else {
                throw JSONAPIError.notJson(data: data)
        }
        
        let included = jsonObject?[JSONAPIKeys.included.rawValue] as? [[String: Any]]
        let links = jsonObject?[JSONAPIKeys.links.rawValue] as? [String: Any]
        
        let json: Any!
        
        if let array = dataObject as? [[String: Any]] {
            json = array.map({ buildCodableJSON(object: $0, included: included ?? [], links: links, option: option) }).compactMap({ $0 })
        } else if let object = dataObject as? [String: Any] {
            json = buildCodableJSON(object: object, included: included ?? [], links: links, option: option)
        } else {
            throw JSONAPIError.notDecodable(type: T.self as! AnyClass)
        }
        
        if let json = json {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                
                let codable = try JSONDecoder().decode(T.self, from: jsonData)
                return codable
            } catch {
                throw JSONAPIError.badRoot(json: json)
            }
        }
        
        throw JSONAPIError.notDecodable(type: T.self as! AnyClass)
    }
    
    private func buildCodableRelations(object: [String: Any], included: [[String: Any]]) -> [String: Any]? {
        var json = [String: Any]()
        
        guard let relations = object[JSONAPIKeys.relationships.rawValue] as? [String: Any], !relations.isEmpty else {
            return nil
        }
        
        let build: ([String: Any]) -> [String: Any]? = { object in
            var json = [String: Any]()
            if let identifiers = self.buildIdentifiers(object: object) {
                json.merge(identifiers, uniquingKeysWith: { a, b in a })
                
                if let includedData = self.getIncludedData(included: included, identifier: object.identifier!) {
                    return self.buildCodableJSON(object: includedData, included: included, links: nil, option: self.decodingOption)
                }
            }
            return json
        }
        
        var relation: Any!
        
        for relationKey in relations.keys {
            
            if let relationObject = relations[relationKey] as? [String: Any] {
                
                let relationDataObject = relationObject[JSONAPIKeys.data.rawValue]
                
                if let array = relationDataObject as? [[String: Any]] {
                    
                    let mapped = array.map(build).compactMap({ $0 })
                    
                    if !mapped.isEmpty {
                        relation = mapped
                    }
                    
                    json[relationKey] = relation
                    
                } else if let object = relationDataObject as? [String: Any] {
                    
                    if let builded = build(object) {
                        json[relationKey] = builded
                    }
                    
                }
            }
        }
        
        return json
    }
    
    private func buildIdentifiers(object: [String: Any]) -> [String: Any]? {
        var json = [String: Any]()
        
        guard let identifier = object[JSONAPIKeys.id.rawValue] as? String, let type = object[JSONAPIKeys.type.rawValue] as? String else {
            return nil
        }
        
        json[JSONAPIKeys.id.rawValue] = identifier
        json[JSONAPIKeys.type.rawValue] = type
        
        return json
    }
    
    private func buildCodableAttributes(object: [String: Any]) -> [String: Any]? {
        guard let attributes = object[JSONAPIKeys.attributes.rawValue] as? [String: Any] else {
            return nil
        }
        
        var json = [String: Any]()
        for attribute in attributes.keys {
            json[attribute] = attributes[attribute]
        }
        
        return json
    }
    
    private func buildCodableJSON(object: [String: Any], included: [[String: Any]], links: [String: Any]?, option: DecodingOption) -> [String: Any]? {
        var json = [String: Any]()
        
        guard let identifiers = buildIdentifiers(object: object) else {
            return nil
        }
        
        json.merge(identifiers, uniquingKeysWith: { a, b in a })
        
        if let attributes = buildCodableAttributes(object: object) {
            json.merge(attributes, uniquingKeysWith: { a, b in a })
        }
        
        if let relations = buildCodableRelations(object: object, included: included) {
            json.merge(relations, uniquingKeysWith: { a, b in a })
        }
        
        if case .rootLevelLinksOverride = option, let links = links {
            json[JSONAPIKeys.links.rawValue] = links
        } else if case .objectLevelLinksOverride = option, let links = object.links {
            json[JSONAPIKeys.links.rawValue] = links
        }
        
        if let meta = object.meta {
            json[JSONAPIKeys.meta.rawValue] = meta
        }
        
        return json
    }
    
    private func  getIncludedData(included: [[String: Any]], identifier: String) -> [String: Any]? {
        return included.first(where: {
            $0.identifier! == identifier
        })
    }
    
}
