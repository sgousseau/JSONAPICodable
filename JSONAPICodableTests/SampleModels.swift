import Foundation

class TopObject: JSONAPICodable, Equatable {
    var id: String
    var type: String = "objects"
    var name: String
    var second: SecondObject
    
    static func == (lhs: TopObject, rhs: TopObject) -> Bool {
        return (lhs.id == rhs.id) && (lhs.type == rhs.type) && (lhs.name == rhs.name) && (lhs.second == rhs.second)
    }
}

class SecondObject: JSONAPICodable, Equatable {
    var id: String
    var type: String = "secondobjects"
    var name: String
    var third: ThirdObject?
    
    static func == (lhs: SecondObject, rhs: SecondObject) -> Bool {
        return (lhs.id == rhs.id) && (lhs.type == rhs.type) && (lhs.name == rhs.name) && (lhs.third == rhs.third)
    }
}

class ThirdObject: JSONAPICodable, Equatable {
    var id: String
    var type: String = "thirdobjects"
    var name: String
    var fourth: FourthObject?
    
    static func == (lhs: ThirdObject, rhs: ThirdObject) -> Bool {
        return (lhs.id == rhs.id) && (lhs.type == rhs.type) && (lhs.name == rhs.name)
    }
}

class FourthObject: Codable {
    var id: String
    var type: String = "fourthobjects"
}

class ATM: JSONAPICodable, Equatable {
    var id: String
    var type: String = "atms"
    var name: String
    var cash: [Cash]
    
    init(id: String, name: String, cash: [Cash]) {
        self.id = id
        self.name = name
        self.cash = cash
    }
    
    static func == (lhs: ATM, rhs: ATM) -> Bool {
        return (lhs.id == rhs.id) && (lhs.type == rhs.type) && (lhs.name == rhs.name) && (lhs.cash.count == rhs.cash.count)
    }
}

class Cash: JSONAPICodable {
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

class Car: JSONAPICodable, Equatable {
    var id: String
    var type: String = "cars"
    var name: String
    var wheels: [Wheel]
    
    init(id: String, name: String, wheels: [Wheel]) {
        self.id = id
        self.name = name
        self.wheels = wheels
    }
    
    static func == (lhs: Car, rhs: Car) -> Bool {
        return (lhs.id == rhs.id) && (lhs.type == rhs.type) && (lhs.name == rhs.name) && (lhs.wheels.count == rhs.wheels.count)
    }
}

class Wheel: JSONAPICodable {
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

class Tire: JSONAPICodable, Equatable {
    var id: String
    var type: String = "tires"
    var name: String
    var model: String
    
    init(id: String, name: String, model: String) {
        self.id = id
        self.name = name
        self.model = model
    }
    
    static func == (lhs: Tire, rhs: Tire) -> Bool {
        return (lhs.id == rhs.id) && (lhs.type == rhs.type) && (lhs.name == rhs.name) && (lhs.model == rhs.model)
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
