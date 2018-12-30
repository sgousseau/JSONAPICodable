import Foundation

public final class JSONAPIDecoder {
    
    public init() {}
    
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? JSON,
            let dataObject = jsonObject?["data"]
            else {
                throw JSONAPIError.notJson(data: data)
        }
        
        let included = jsonObject?["included"] as? [JSON]
        
        let json: Any!
        
        if let array = dataObject as? [JSON] {
            json = array.map({ buildCodableJSON(object: $0, included: included ?? []) }).compactMap({ $0 })
        } else if let object = dataObject as? JSON {
            json = buildCodableJSON(object: object, included: included ?? [])
        } else {
            throw JSONAPIError.notCodable(type: T.self as! AnyClass)
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        //print(String(data: jsonData, encoding: .utf8)!)
        let codable = try JSONDecoder().decode(T.self, from: jsonData)
        return codable
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
                
                if let identifier = identifiers["id"] as? String, let type = identifiers["type"] as? String {
                    if let includedData = self.getIncludedData(included: included, identifier: identifier, type: type) {
                        return self.buildCodableJSON(object: includedData, included: included)
                    }
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
    
    private func buildCodableJSON(object: JSON, included: [JSON]) -> JSON? {
        var json = JSON()
        
        guard let identifiers = buildIdentifiers(object: object) else {
            //debugPrint("No identifiers")
            return nil
        }
        
        //debugPrint("buildCodableJSON", "\(identifiers)")
        
        json.merge(identifiers, uniquingKeysWith: { a, b in a })
        
        if let attributes = buildCodableAttributes(object: object) {
            json.merge(attributes, uniquingKeysWith: { a, b in a })
        }
        
        if let relations = buildCodableRelations(object: object, included: included) {
            json.merge(relations, uniquingKeysWith: { a, b in a })
        }
        
        return json
    }
    
    private func  getIncludedData(included: [JSON], identifier: String, type: String) -> JSON? {
        return included.first(where: {
            ($0["id"] as? String ?? "") == identifier && ($0["type"] as? String ?? "") == type
        })
    }
    
}
