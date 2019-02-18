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

Use like JSONEncoder() and JSONDecoder(). Simply use JSONAPIEncoder().encode(object:) and JSONAPIDecoder().decode(object:)

```
try JSONAPIDecoder().decode(Model.self, from: data)
```

```
try JSONAPIEncoder().encode(object: Encodable)
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

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Thanks to Charlie Eissen for explanation and teaching about json:api standard
