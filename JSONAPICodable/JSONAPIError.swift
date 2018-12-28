import Foundation

public enum JSONAPIError: Error {
    case encodeNil
    case notCodable(type: AnyClass)
    case notJson(data: Data)
    case notJsonApiCompatible(object: Any)
    case badRoot(json: JSON)
    case hasNoDataKey(json: JSON)
    case hasNoLinksKey(json: JSON)
    case hasNoAttributesKey(json: JSON)
    case hasNoRelationshipsKey(json: JSON)
    case hasNoIncludedKey(json: JSON)
    case hasNoFilterKey(json: JSON)
}
