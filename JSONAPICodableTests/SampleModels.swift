import Foundation

class TopObject: Codable {
    var id: String
    var type: String = "objects"
    var name: String
    var second: SecondObject
}

class SecondObject: Codable {
    var id: String
    var type: String = "secondobjects"
    var name: String
    var third: ThirdObject?
}

class ThirdObject: Codable {
    var id: String
    var type: String = "thirdobjects"
    var name: String
    var fourth: FourthObject?
}

class FourthObject: Codable {
    var id: String
    var type: String = "fourthobjects"
}

class ATM: Codable {
    var id: String
    var type: String = "atms"
    var name: String
    var cash: [Cash]
    
    init(id: String, name: String, cash: [Cash]) {
        self.id = id
        self.name = name
        self.cash = cash
    }
}

class Cash: Codable {
    var id: String
    var type: String = "cashs"
    var value: Int
    var count: Int
    
    init(id: String, value: Int, count: Int) {
        self.id = id
        self.value = value
        self.count = count
    }
}

enum Material: String {
    case iron
    case wood
    
    init() {
        self = .iron
    }
}

class Links: Codable {
    var current: String?
    var next: String?
    var previous: String?
    var last: String?
}

class Car: Codable {
    var id: String
    var type: String = "cars"
    var name: String
    var wheels: [Wheel]
    
    init(id: String, name: String, wheels: [Wheel]) {
        self.id = id
        self.name = name
        self.wheels = wheels
    }
}

class Wheel: Codable {
    var id: String
    var type: String = "wheels"
    var name: String
    var tire: Tire
    
    init(id: String, tire: Tire) {
        self.id = id
        self.name = "\(id)-\(tire.model)"
        self.tire = tire
    }
}

class Tire: Codable {
    var id: String
    var type: String = "tires"
    var name: String
    var model: String
    
    init(id: String, name: String, model: String) {
        self.id = id
        self.name = name
        self.model = model
    }
}

class Wallet: Codable {
    let id: String
    let type: String = "wallets"
    var bitcoins: [BitCoinWallet]
    
    init(id: String, bitcoinWallets: [BitCoinWallet]) {
        self.id = id
        bitcoins = bitcoinWallets
    }
}

class BitCoinWallet: Codable {
    let id: String
    let type: String = "bitcoinwallets"
    let keys: [String]
    let additional: BitcoinWalletMeta
    
    init(id: String) {
        self.id = id
        keys = ["kA", "kB", "kC"]
        additional = BitcoinWalletMeta()
    }
}

class BitcoinWalletMeta: Codable, JSONAPIAttributeExpressible {
    let id: String = "add0"
    let type: String = "additionals"
    let info: String
    let link: String
    
    init() {
        info = "meta:info"
        link = "meta:link"
    }
}

class User: Codable {
    let id: String
    let type: String = "users"
    let info: String
    let location: Location?
    
    init(id: String, info: String, location: Location) {
        self.id = id
        self.info = info
        self.location = location
    }
}

class Location: Codable {
    let id: String
    let type: String = "locations"
    let region: Region
    
    init(id: String, region: Region) {
        self.id = id
        self.region = region
    }
}

class Region: Codable {
    let id: String
    let name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

class Article: Codable {
    var id: String
    let type = "articles"
    var title: String
    var author: People
    var comments: [Comment]
    
    init(id: String, title: String, author: People, comments: [Comment]) {
        self.id = id
        self.title = title
        self.author = author
        self.comments = comments
    }
}

class People: Codable {
    var id: String
    let type = "people"
    var lastname: String
    var firstname: String
    var twitter: String
    var links: SelfLink
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case lastname = "last-name"
        case firstname = "first-name"
        case twitter
        case links
    }
    
    init(id: String, firstname: String, lastname: String, twitter: String, links: SelfLink) {
        self.id = id
        self.firstname = firstname
        self.lastname = lastname
        self.twitter = twitter
        self.links = links
    }
}

class Comment: Codable {
    var id: String
    let type = "comments"
    var body: String
    var links: SelfLink
    
    init(id: String, body: String, twitter: String, links: SelfLink) {
        self.id = id
        self.body = body
        self.links = links
    }
}

class SelfLink: Codable {
    var this: String
    
    init(this: String) {
        self.this = this
    }
    
    enum CodingKeys: String, CodingKey {
        case this = "self"
    }
}

class RelatedLink: Codable {
    var this: String
    var related: String
    
    init(this: String, related: String) {
        self.this = this
        self.related = related
    }
    
    enum CodingKeys: String, CodingKey {
        case this = "self"
        case related
    }
}

class RelatedMetaLink: Codable {
    var this: String
    var related: Meta
    
    init(this: String, related: Meta) {
        self.this = this
        self.related = related
    }
    
    enum CodingKeys: String, CodingKey {
        case this = "self"
        case related
    }
}

class Meta: Codable {
    
}

class Package: Codable {
    var id: String
    var type: String = "packages"
    var title: String?
    var quantityExpected: Int?
    var recipient: String?
    var sender: String?
    var availableSince: String?
    var status: PackageStatus?
    
    var links: PaginationLinks?
}

struct PaginationLinks: Codable {
    let first: String?
    let prev: String?
    let next: String?
    let last: String?
}

class PackageStatus: Codable {
    var id: String
    var type: String = "packageStatus"
    var code: String?
    var lastUpdate: String
    
}
