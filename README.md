# JSONAPICodable

JSON:API Standard for Swift and Codable types.

## Getting Started

### Installing

```
pod 'JSONAPICodable'
```

```
pod install
```

### Usage

Use like JSONEncoder() and JSONDecoder(). Models have to be Encodable do be used with JSONAPIEncoder, and Decodable with JSONAPIDecoder.

```swift
try JSONAPIDecoder().decode(Model.self, from: data)
try JSONAPIDecoder().decode([Model].self, from: data)
```

```swift
try JSONAPIEncoder().encode(Encodable)
```

### How it works

Swift only understand JSON format for the new Codable structures. So, the key principle is to convert any JSON:API format to an understandable JSON for our Codables at decoding. At encoding, the same process is applied, the JSON issued by JSONEncoder will be converted to a JSON:API.

This method ensure that you can keep the flexibility of Codable structures, with Coding keys support. Custom decoding and encoding strategy are not yet supported.

In short:

A root object will be serialized only if it contains 2 variables: 
```swift
let id: String
let type: String
```
Let or Var is  at your convenance, there is no type conflict if you declare two structures with the same type. The JSONAPIDecoder will just try to instanciate the structure with the JSON format.

A nested object will be serialized as a Relationship if it comforms to the above rule (id and type variables).

A nested object will be serialized as an attribute if it has a missing id or type variable. Also, you can extend your object type to be JSONAPIAttributeExpressible to force the serialization as an attribute. A primitive, an array of primitive, a JSONAPIAttributeExpressible, an array of JSONAPIAttributeExpressible, will all be serialized as an attribute.

Any object can contains links or meta. 

A meta property will be serialized as it. 
```swift
var meta: MetaObject
```
A links property will be serialized as it. 
```swift
var links: LinksObject
```

The only exeption for now is for an array decoding, the root links are to be serialized in each decoded objects instead of a root document containing the array of objects plus the metas. That means links or meta at root level would override links or meta at object level. This is a temporary behavior waiting other decoding/encoding options.

### Error handling WIP

JSONAPIEncoder and JSONAPIDecoder will throw errors of type JSONAPIError: Error, in addition to the JSONEncoder and JSONDecoder errors.

JSONAPIEncoder errors:
```swift
  case badRoot(json: JSON)
  case notJsonApiCompatible(object: Any)
```
JSONAPIDecoder errors:
```swift
  case notJson(data: Data)
  case notDecodable(type: AnyClass)
```

## Deployment

iOS 7.0+
macOS 10.9+
tvOS 9.0+
watchOS 2.0+
Xcode 9.0+

## Authors

* **Sébastien Gousseau** - [Sgousseau](https://github.com/sgousseau)

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/sgousseau/JSONAPICodable/blob/master/LICENSE) file for details

## Acknowledgments

* Thanks to Charlie Eissen for explanation and teaching about json:api standard
