import Foundation

public final class JSONAPIEncoder {
    
    enum IdEncodingStrategy {
        case emptyId
        case randomId
    }
//    enum Options {
//        case withoutId
//        case randomId
//    }
//
//    private var options = Options.withoutId
    private var encodingStrategy: IdEncodingStrategy = .randomId
    
    private typealias ObjectEnumeration = (object: Any, attributes: [Mirror.Child], objects: [Mirror.Child])
    private typealias ObjectIdentifier = (id: String, type: String)
    
    private var _allIncluded = JSON()
    private var _allIncludedForbidden = [String]()
    
    public init() {}
    
    public func encode(object: Any) throws -> Data {
        return try JSONSerialization.data(withJSONObject: encodeJSON(from: object), options: .prettyPrinted)
    }
    
    private func encodeJSON(from object: Any) throws -> JSON {
        _allIncluded.removeAll()
        
        let build: (Any) throws -> JSON = { [unowned self] object in
            guard let identifiers = self.encodeIdentifiers(object) else {
                throw JSONAPIError.notJsonApiCompatible(object: object)
            }
            
            self._allIncludedForbidden.append("\(identifiers.type):\(identifiers.id)")
            
            let enumeration = try self.objectEnumerate(object: object)
            
            //debugPrint("encode object \(object) of type \(identifiers.type) with id \(identifiers.id)")
            
            try self.encodeIncluded(object: object)
            
            return try self.buildObject(identifiers: identifiers, enumeration: enumeration)
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
        return _allIncluded
            .map({ $0.value as? JSON ?? JSON()})
            .filter({ (json) -> Bool in
                let id = json["id"] as! String
                let type = json["type"] as! String
                return !_allIncludedForbidden.contains("\(type):\(id)")
            })
    }
    
    private func encodeIdentifiers(_ object: Any) -> (id: String, type: String)? {
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
    
    private func encodeIncluded(object: Any) throws {
        
        print("encode included for type: \(type(of: object))")
        
        var value: Any
        if let optional = object as? OptionalProtocol, optional.isSome() {
            value = optional.unwrap()
        } else {
            value = object
        }
        
        let enumeration = try objectEnumerate(object: value)
        
//        let description =
//        """
//        encode included for \(object),
//            attributes: \(enumeration.attributes.map({ $0.label! }).joined(separator: ", ")),
//            objects: \(enumeration.objects.map({ "\(type(of: $0.value))" }).joined(separator: ", "))
//        """
//
        //debugPrint(description)
        
        try enumeration.objects.forEach({ try encodeIncluded(object: $0.value) })
    
        guard let identifiers = encodeIdentifiers(value), _allIncluded[identifiers.id] == nil else {
            return
        }
        
        let build = try buildObject(identifiers: identifiers, enumeration: enumeration)
        _allIncluded["\(identifiers.type):\(identifiers.id)"] = build
    }
    
    private func encodeRelations(enumeration: ObjectEnumeration) throws -> JSON? {
        //debugPrint("encode relations for \(enumeration.object)")
        
        var relations = JSON()
        
        for property in enumeration.objects {
            if let label = property.label {
                if let optional = property.value as? OptionalProtocol {
                    if optional.isSome() {
                        if let json = try encodeRelation(object: optional.unwrap(), key: label) {
                            relations.merge(json, uniquingKeysWith: { a, b in a })
                        }
                    } else {
                        //debugPrint("\(label) -> optional nil")
                    }
                } else if let json = try encodeRelation(object: property.value, key: label) {
                    relations.merge(json, uniquingKeysWith: { a, b in a })
                }
            }
        }
        
        return relations.isEmpty ? nil : ["relationships": relations]
    }
    
    private func encodeRelation(object: Any, key: String) throws -> JSON? {
        
        if let array = object as? [Any] {
            //debugPrint("encode relation as an Array for key: \(key)")
            var values = [JSON]()
            for object in array {
                let enumeration = try objectEnumerate(object: object)
                var current = JSON()
                for property in enumeration.attributes {
                    if let label = property.label {
                        if label == "id" || label == "type" {
                            let json = self.json(property)
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
            let enumeration = try objectEnumerate(object: object)
            
            for property in enumeration.attributes {
                if let label = property.label {
                    if label == "id" || label == "type" {
                        let json = self.json(property)
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
                if label != "id" && label != "type" {
                    let json = self.json(property)
                    attributes.merge(json, uniquingKeysWith: { a, b in a })
                }
            }
        }
    
        return attributes.isEmpty ? nil : ["attributes": attributes]
    }
    
    private func buildObject(identifiers: ObjectIdentifier, enumeration: ObjectEnumeration) throws -> JSON {
        //debugPrint("building \(identifiers.id):\(identifiers.type)")
        
        var json = JSON()
        
        json["id"] = identifiers.id
        json["type"] = identifiers.type
        
        if let attributes = encodeAttributes(enumeration: enumeration) {
            json.merge(attributes, uniquingKeysWith: { a, b in a })
        }
        
        if let relations = try encodeRelations(enumeration: enumeration) {
            json.merge(relations, uniquingKeysWith: { a, b in a })
        }
        
//        if let links = links {
//            json.merge(links, uniquingKeysWith: { a, b in a })
//        }
        
        return json
    }
    
    private func objectEnumerate(object: Any) throws -> ObjectEnumeration {
        
        print("objectEnumerate", type(of: object))
        
        var attributes = [Mirror.Child]()
        var objects = [Mirror.Child]()
        
        for property in Mirror(reflecting: object).children {
            print("\t", property.label ?? "item of array,", type(of: property.value))
            
            if isAnAttribute(property) {
                attributes.append(property)
            } else if isCodableAsRelation(property) {
                objects.append(property)
            } else {
                print("something wrong with this property")
                throw JSONAPIError.notJsonApiCompatible(object: property.value)
            }
        }
        
        print("\t\t->", "attributes:\(attributes.count), objects:\(objects.count)")
        
        return (object: object, attributes: attributes, objects: objects)
    }
    
    private func json(_ property: Mirror.Child) -> JSON {
        return [property.label!: asItOrJson(property.value)]
    }
    
    private func asItOrJson(_ object: Any) -> Any {
        if isPrimitive(object) || isArrayOfPrimitive(object) {
            return object
        } else if let sequence = object as? [Any] {
            return sequence.map({ ($0 as! Encodable).dictionary }).compactMap({ $0 })
        } else if let _ = object as? Encodable {
            return (object as! Encodable).dictionary ?? object
        }
        return object
    }
    
    private func isAnAttribute(_ property: Mirror.Child) -> Bool {
        if isPrimitive(property.value) {
            return true
        } else if isArrayOfPrimitive(property.value) {
            return true
        } else if let _ = property.value as? JSONAPIAttributeExpressible {
            return true
        } else if let _ = property.value as? [JSONAPIAttributeExpressible] {
            return true
        }
        return isCodableAsAttribute(property)
    }
    
    private func isCodableAsAttribute(_ property: Mirror.Child) -> Bool {
        return isCodableAsAttribute(property.value)
    }
    
    private func isCodableAsAttribute(_ value: Any) -> Bool {
        if let array = value as? [Any] {
            return array.reduce(true) { isCodableAsAttribute($1) && $0 }
        }
        return encodeIdentifiers(value) == nil
    }
    
    private func isCodableAsRelation(_ property: Mirror.Child) -> Bool {
        return isCodableAsRelation(property.value)
    }
    
    private func isCodableAsRelation(_ value: Any) -> Bool {
        if let array = value as? [Any] {
            return array.reduce(true) { isCodableAsRelation($1) && $0 }
        }
        return encodeIdentifiers(value) != nil //missing either id or type variable, cant be serialized as a relation
    }
    
    private func isArrayOfPrimitive(property: Mirror.Child) -> Bool {
        return isArrayOfPrimitive(property.value)
    }
    
    private func isArrayOfPrimitive(_ value: Any) -> Bool {
        let propertyMetaType = type(of: value)
        
        if propertyMetaType is [String].Type {
            return true
        } else if propertyMetaType is Optional<[String]>.Type {
            return true
        } else if propertyMetaType is [Int].Type {
            return true
        } else if propertyMetaType is Optional<[Int]>.Type {
            return true
        } else if propertyMetaType is [Double].Type {
            return true
        } else if propertyMetaType is Optional<[Double]>.Type {
            return true
        } else if propertyMetaType is [Float].Type {
            return true
        } else if propertyMetaType is Optional<[Float]>.Type {
            return true
        } else if propertyMetaType is [Bool].Type {
            return true
        } else if propertyMetaType is Optional<[Bool]>.Type {
            return true
        }
        return false
    }
    
    private func isPrimitive(property: Mirror.Child) -> Bool {
        return isPrimitive(property.value)
    }
    
    private func isPrimitive(_ value: Any) -> Bool {
        let propertyMetaType = type(of: value)
        
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
        return self["type"] as? String
    }
    
    var identifiers: [Key: Value]? {
        return id != nil && type != nil ? ["id": id!, "type": type!] : nil
    }
}

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}

extension Sequence where Iterator.Element: Encodable {
    
    var sequenceDictionary: [[String: Any]] {
        return reduce([], { collection, element in collection + [element.dictionary] }).compactMap({ $0 })
    }
}

//extension Sequence where Iterator.Element: Equatable {
//    func unique() -> [Iterator.Element] {
//        return reduce([], { collection, element in collection.contains(element) ? collection : collection + [element] })
//    }
//}
