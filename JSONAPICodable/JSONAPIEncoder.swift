import Foundation

final class JSONAPIEncoder {
    
//    enum Options {
//        case withoutId
//        case randomId
//    }
//
//    private var options = Options.withoutId
    
    private typealias ObjectEnumeration = (object: Any, attributes: [Mirror.Child], objects: [Mirror.Child])
    private typealias ObjectIdentifier = (id: String, type: String)
    
    private var _allIncluded = JSON()
    private var _allIncludedForbidden = [String]()
    
    func encode(object: Any) throws -> Data {
        return try JSONSerialization.data(withJSONObject: encodeJSON(from: object), options: .prettyPrinted)
    }
    
    private func encodeJSON(from object: Any) throws -> JSON {
        _allIncluded.removeAll()
        
        let build: (Any) throws -> JSON = { [unowned self] object in
            guard let identifiers = self.encodeIdentifiers(object: object) else {
                throw JSONAPIError.notJsonApiCompatible(object: object)
            }
            
            self._allIncludedForbidden.append("\(identifiers.type):\(identifiers.id)")
            
            let enumeration = self.objectEnumerate(object: object)
            
            //debugPrint("encode object \(object) of type \(identifiers.type) with id \(identifiers.id)")
            
            self.encodeIncluded(object: object)
            
            return self.buildObject(identifiers: identifiers, enumeration: enumeration)
        }
        
        var json = JSON()
        
        if let objects = object as? [Any] {
            json["data"] = try objects.map(build)

        } else {
            json["data"] = try build(object)
        }
        
        if json["data"] != nil {
            let included = parseIncluded()
            if !included.isEmpty {
                json["included"] = included
            }
            
            return json
        }
        
        throw JSONAPIError.notJsonApiCompatible(object: object)
    }
    
    private func parseIncluded() -> [JSON] {
        //print(_allIncluded.keys)
        return _allIncluded
            .map({ $0.value as? JSON ?? JSON()})
            .filter({ (json) -> Bool in
                let id = json["id"] as! String
                let type = json["type"] as! String
                return !_allIncludedForbidden.contains("\(type):\(id)")
            })
    }
    
    private func encodeIdentifiers(object: Any) -> (id: String, type: String)? {
        if let object = object as? JSON, let id = object["id"] as? String, let type = object["type"] as? String {
            return (id: id, type: type)
        } else {
            let mirror = Mirror(reflecting: object)
            guard let id = mirror.children.first(where: { $0.label == "id" })?.value as? String,
                let type = mirror.children.first(where: { $0.label == "type" })?.value as? String else {
                    return nil
            }
            
            return (id: id, type: type)
        }
    }
    
    private func encodeIncluded(object: Any) {
        
        var value: Any
        if let optional = object as? OptionalProtocol, optional.isSome() {
            value = optional.unwrap()
        } else {
            value = object
        }
        
        let enumeration = objectEnumerate(object: value)
        
//        let description =
//        """
//        encode included for \(object),
//            attributes: \(enumeration.attributes.map({ $0.label! }).joined(separator: ", ")),
//            objects: \(enumeration.objects.map({ "\(type(of: $0.value))" }).joined(separator: ", "))
//        """
//        
        //debugPrint(description)
        
        enumeration.objects.forEach({ encodeIncluded(object: $0.value) })
    
        guard let identifiers = encodeIdentifiers(object: value), _allIncluded[identifiers.id] == nil else {
            return
        }
        
        let build = buildObject(identifiers: identifiers, enumeration: enumeration)
        _allIncluded["\(identifiers.type):\(identifiers.id)"] = build
    }
    
    private func encodeRelations(enumeration: ObjectEnumeration) -> JSON? {
        //debugPrint("encode relations for \(enumeration.object)")
        
        var relations = JSON()
        
        for property in enumeration.objects {
            if let label = property.label {
                if let optional = property.value as? OptionalProtocol {
                    if optional.isSome() {
                        if let json = encodeRelation(object: optional.unwrap(), key: label) {
                            relations.merge(json, uniquingKeysWith: { a, b in a })
                        }
                    } else {
                        //debugPrint("\(label) -> optional nil")
                    }
                } else if let json = encodeRelation(object: property.value, key: label) {
                    relations.merge(json, uniquingKeysWith: { a, b in a })
                }
            }
        }
        
        return relations.isEmpty ? nil : ["relationships": relations]
    }
    
    private func encodeRelation(object: Any, key: String) -> JSON? {
        
        if let array = object as? [Any] {
            //debugPrint("encode relation as an Array for key: \(key)")
            var values = [JSON]()
            for object in array {
                let enumeration = objectEnumerate(object: object)
                var current = JSON()
                for property in enumeration.attributes {
                    if let label = property.label {
                        if let json = encodePrimitive(label: label, value: property.value), (label == "id" || label == "type") {
                            current.merge(json, uniquingKeysWith: { a, b in a })
                        }
                    }
                }
                values.append(current)
            }
            
            return values.isEmpty ? nil : [key: ["data": values]]
            
        } else {
            //debugPrint("encode relation for \(object), relationKey: \(key)")
            var values = JSON()
            let enumeration = objectEnumerate(object: object)
            
            for property in enumeration.attributes {
                if let label = property.label {
                    if let json = encodePrimitive(label: label, value: property.value), (label == "id" || label == "type") {
                        values.merge(json, uniquingKeysWith: { a, b in a })
                    }
                }
            }
            
            return values.isEmpty ? nil : [key: ["data": values]]
        }
    }

    private func encodeAttributes(enumeration: ObjectEnumeration) -> JSON? {
        //debugPrint("encode attributes for \(enumeration.object)")
        
        var attributes = JSON()
        
        for property in enumeration.attributes {
            if let label = property.label {
                if let json = encodePrimitive(label: label, value: property.value), label != "id", label != "type" {
                    attributes.merge(json, uniquingKeysWith: { a, b in a })
                }
            }
        }
        
        return attributes.isEmpty ? nil : ["attributes": attributes]
    }
    
    private func encodePrimitive(label: String, value: Any) -> JSON? {
        return [label: value]
    }
    
    private func buildObject(identifiers: ObjectIdentifier, enumeration: ObjectEnumeration) -> JSON {
        //debugPrint("building \(identifiers.id):\(identifiers.type)")
        
        var json = JSON()
        
        json["id"] = identifiers.id
        json["type"] = identifiers.type
        
        if let attributes = encodeAttributes(enumeration: enumeration) {
            json.merge(attributes, uniquingKeysWith: { a, b in a })
        }
        
        if let relations = encodeRelations(enumeration: enumeration) {
            json.merge(relations, uniquingKeysWith: { a, b in a })
        }
        
//        if let links = links {
//            json.merge(links, uniquingKeysWith: { a, b in a })
//        }
        
        return json
    }
    
    private func objectEnumerate(object: Any) -> ObjectEnumeration {
        //debugPrint(object)
        var attributes = [Mirror.Child]()
        var objects = [Mirror.Child]()
        
        let isArray = ((object as? [Any]) != nil)
        
        for property in Mirror(reflecting: object).children {
            if isPrimitive(property: property) {
                attributes.append(property)
            } else if isArray {
                objects.append(property)
            } else {
                objects.append(property)
            }
        }
        
        return (object: object, attributes: attributes, objects: objects)
    }
    
    private func isPrimitive(property: Mirror.Child) -> Bool {
        let propertyMetaType = type(of: property.value)
        
        if propertyMetaType is String.Type {
            return true
        } else if propertyMetaType is Optional<String>.Type {
            return true
        } else if propertyMetaType is Int.Type {
            return true
        } else if propertyMetaType is Optional<Int>.Type {
            return true
        } else if propertyMetaType is Double.Type {
            return true
        } else if propertyMetaType is Optional<Double>.Type {
            return true
        } else if propertyMetaType is Float.Type {
            return true
        } else if propertyMetaType is Optional<Float>.Type {
            return true
        } else if propertyMetaType is Bool.Type {
            return true
        } else if propertyMetaType is Optional<Bool>.Type {
            return true
        }
        return false
    }
}

fileprivate extension Dictionary where Key == String, Value == Any {
    var id: String? {
        return self["id"] as? String
    }
    
    var type: String? {
        return self["id"] as? String
    }
    
    var identifiers: [Key: Value]? {
        return id != nil && type != nil ? ["id": id!, "type": type!] : nil
    }
}
