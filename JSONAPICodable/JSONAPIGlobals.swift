//
//  JSONAPIGlobals.swift
//  JSONAPICodable
//
//  Created by Sebastien GOUSSEAU (EXT) on 27/05/2019.
//  Copyright © 2019 Chanel. All rights reserved.
//

import Foundation

enum JSONAPIKeys: String {
    case id
    case type
    case attributes
    case relationships
    case links
    case meta
    case data
    case included
}

func uniquingByLast(first: Any, last: Any) -> Any {
    return last
}

func uniquingByFirst(first: Any, last: Any) -> Any {
    return first
}

extension Dictionary where Key == String, Value == Any {
    
    var id: String? {
        return self[JSONAPIKeys.id.rawValue] as? String
    }
    
    var type: String? {
        return self[JSONAPIKeys.type.rawValue] as? String
    }
    
    var identifiers: [Key: Value]? {
        return id != nil && type != nil ? [JSONAPIKeys.id.rawValue: id!, JSONAPIKeys.type.rawValue: type!] : nil
    }
    
    var identifier: String? {
        return id != nil && type != nil ? "\(id!):\(type!)" : nil
    }
    
    var withoutIdentifiers: [Key: Value] {
        var result = self
        result.removeValue(forKey: JSONAPIKeys.id.rawValue)
        result.removeValue(forKey: JSONAPIKeys.type.rawValue)
        return result
    }
    
    var attributes: [Key: Value]? {
        return self[JSONAPIKeys.attributes.rawValue] as? [String: Any]
    }
    
    var relationships: [Key: Value]? {
        return self[JSONAPIKeys.relationships.rawValue] as? [String: Any]
    }
    
    var meta: [Key: Value]? {
        return self[JSONAPIKeys.meta.rawValue] as? [String: Any]
    }
    
    var links: [Key: Value]? {
        return self[JSONAPIKeys.links.rawValue] as? [String: Any]
    }
    
    var included: [[Key: Value]]? {
        return self[JSONAPIKeys.included.rawValue] as? [[String: Any]]
    }
    
    var child: [Key: Value]? {
        return self[JSONAPIKeys.data.rawValue] as? [String: Any]
    }
    
    var children: [[Key: Value]]? {
        return self[JSONAPIKeys.data.rawValue] as? [[String: Any]]
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
