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

Use like JSONEncoder() and JSONDecoder(). 
Simply use JSONAPIEncoder().encode(obj) and JSONAPIDecoder().decode(type, data)

```
try JSONAPIDecoder().decode(Model.self, from: data)
try JSONAPIDecoder().decode([Model].self, from: data)
```

```
try JSONAPIEncoder().encode(Encodable)
```

A root object will be serialized only if it contains 2 principal variables: let id: String, let type: String. Let or Var is  at your convenance, there is no type conflict if you declare two structures with the same type. The JSONAPIDecoder will just try to instanciate the structure with the JSON standard format.

A nested object will be serialized as a Relationship if it comforms to the above rule (id and type variables).

A nested object will be serialized as an attribute if it has a missing id or type variable. Also, you can extend your object type to be JSONAPIAttributeExpressible to force the serialization as an attribute. A primitive, an array of primitive, a JSONAPIAttributeExpressible, an array of JSONAPIAttributeExpressible, will all be serialized as an attribute.

Any object can contains links or meta data. If the Codable definition of the object accept a Link Codable structure, or any other meta structure, it will be serialized too. The only exeption for now is for an array decoding, the root links are to be serialized in each decoded objects instead of a root document containing the array of objects plus the metas.


## Deployment

iOS 7.0+
macOS 10.9+
tvOS 9.0+
watchOS 2.0+
Xcode 9.0+

## Authors

* **Sébastien Gousseau** - [Sgousseau](https://github.com/sgousseau)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Thanks to Charlie Eissen for explanation and teaching about json:api standard
