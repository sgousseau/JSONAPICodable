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
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? JSON,
            let dataObject = jsonObject?["data"]
            else {
                throw JSONAPIError.notJson(data: data)
        }
        
        let included = jsonObject?["included"] as? [JSON]
        let links = jsonObject?["links"] as? JSON
        
        let json: Any!
        
        if let array = dataObject as? [JSON] {
            json = array.map({ buildCodableJSON(object: $0, included: included ?? [], links: links, option: option) }).compactMap({ $0 })
        } else if let object = dataObject as? JSON {
            json = buildCodableJSON(object: object, included: included ?? [], links: links, option: option)
        } else {
            throw JSONAPIError.notDecodable(type: T.self as! AnyClass)
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        
//        #if DEBUG
//        print("JSON:API")
//        print(String(data: jsonData, encoding: .utf8)!)
//        #endif
        let codable = try JSONDecoder().decode(T.self, from: jsonData)
        return codable
    }
    
    private func json(data: Data) throws -> JSON? {
        
        return nil
    }
    
    private func jsonapi(json: JSON) throws -> JSON? {
        
        return nil
    }
    
    private func buildCodableRelations(object: JSON, included: [JSON]) -> JSON? {
        var json = JSON()
        
        guard let relations = object["relationships"] as? JSON, !relations.isEmpty else {
            return nil
        }
        
        let build: (JSON) -> JSON? = { object in
            var json = JSON()
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
            
            if let relationObject = relations[relationKey] as? JSON {
                
                let relationDataObject = relationObject["data"]
                
                if let array = relationDataObject as? [JSON] {
                    
                    let mapped = array.map(build).compactMap({ $0 })
                    
                    if !mapped.isEmpty {
                        relation = mapped
                    }
                    
                    json[relationKey] = relation
                    
                } else if let object = relationDataObject as? JSON {
                    
                    if let builded = build(object) {
                        json[relationKey] = builded
                    }
                    
                }
            }
        }
        
        return json
    }
    
    private func buildIdentifiers(object: JSON) -> JSON? {
        var json = JSON()
        
        guard let identifier = object["id"] as? String, let type = object["type"] as? String else {
            //debugPrint("No identifiers...")
            return nil
        }
        
        json["id"] = identifier
        json["type"] = type
        
        //debugPrint("buildIdentifiers", identifier, type)
        
        return json
    }
    
    private func buildCodableAttributes(object: JSON) -> JSON? {
        guard let attributes = object["attributes"] as? JSON else {
            //debugPrint("No attributes...")
            return nil
        }
        
        var json = JSON()
        for attribute in attributes.keys {
            json[attribute] = attributes[attribute]
        }
        
        //debugPrint("buildCodableAttributes", "\(attributes)")
        
        return json
    }
    
    private func buildCodableJSON(object: JSON, included: [JSON], links: JSON?, option: DecodingOption) -> JSON? {
        var json = JSON()
        
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
            json["links"] = links
        } else if case .objectLevelLinksOverride = option, let links = object.links {
            json["links"] = links
        }
        
        if let meta = object.meta {
            json["meta"] = meta
        }
        
        return json
    }
    
    private func  getIncludedData(included: [JSON], identifier: String) -> JSON? {
        return included.first(where: {
            $0.identifier! == identifier
        })
    }
    
}
