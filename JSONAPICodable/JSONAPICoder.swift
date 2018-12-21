import Foundation

class JSONAPICoder {
    
    func encode<T>(object: T) throws -> Data where T: Any {
        return try JSONAPIEncoder().encode(object: object)
    }
    
    func decode<T>(_ type: T.Type, from data: Data) throws -> T? where T: Decodable {
        return try JSONAPIDecoder().decode(type, from: data)
    }
}
