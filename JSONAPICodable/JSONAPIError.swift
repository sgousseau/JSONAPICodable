import Foundation

private typealias JSON = [String: Any]

public enum JSONAPIError: Error {
    case encodeNil
    case notDecodable(type: AnyClass)
    case notJson(data: Data)
    case notJsonApiCompatible(object: Any)
    case badRoot(json: Any)
    case hasNoDataKey(json: [String: Any])
    case hasNoLinksKey(json: [String: Any])
    case hasNoAttributesKey(json: [String: Any])
    case hasNoRelationshipsKey(json: [String: Any])
    case hasNoIncludedKey(json: [String: Any])
    case hasNoFilterKey(json: [String: Any])
    
    public var localizedDescription: String {
        return "\(self)"
    }
}
