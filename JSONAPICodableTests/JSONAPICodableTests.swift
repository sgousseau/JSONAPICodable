import XCTest
@testable import JSONAPICodable

class JSONAPICodableTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

//    func testNestedObjects() {
//        let bundle = Bundle(for: JSONAPICodableTests.self)
//        let nestedObjectsData = try! String(contentsOfFile: bundle.path(forResource: "NestedObjects", ofType: "json")!).data(using: .utf8)!
//
//        do {
//            let object = try JSONAPIDecoder().decode(TopObject.self, from: nestedObjectsData)
//            let encoded = try JSONAPIEncoder().encode(object: object)
//            let inverse = try JSONAPIDecoder().decode(TopObject.self, from: encoded)
//
//            XCTAssert(object == inverse, "Inverse serialization object should produce same object")
//        } catch {
//            XCTAssert(false, error.localizedDescription)
//        }
//    }
//
//    func testNestedArrays() {
//        let tickets0 = Cash(id: "cash0", value: 10, count: 10)
//        let tickets1 = Cash(id: "cash1", value: 5, count: 5)
//        let atm = ATM(id: "atm0", name: "atm madeleine", cash: [tickets0, tickets1])
//
//        do {
//            let encoded = try JSONAPIEncoder().encode(object: atm)
//            let inverse = try JSONAPIDecoder().decode(ATM.self, from: encoded)
//            XCTAssert(atm == inverse, "Inverse serialization object should produce same object")
//        } catch {
//            XCTAssert(false, error.localizedDescription)
//        }
//    }
//
//    func testNestedArrays2() {
//        let goodYear = Tire(id: "tire0", name: "GoodYear-Sport-Tire", model: "gy-sp00-19p-22p")
//        let wheels = [Wheel(id: "wheel0", tire: goodYear), Wheel(id: "wheel1", tire: goodYear), Wheel(id: "wheel2", tire: goodYear), Wheel(id: "wheel3", tire: goodYear)]
//        let audi = Car(id: "car0", name: "Audi S3", wheels: wheels)
//
//        do {
//            let encoded = try JSONAPIEncoder().encode(object: audi)
//            let inverse = try JSONAPIDecoder().decode(Car.self, from: encoded)
//            XCTAssert(audi == inverse, "Inverse serialization object should produce same object")
//        } catch {
//            XCTAssert(false, error.localizedDescription)
//        }
//    }
//    
//    func testArrays() {
//        let goodyear = Tire(id: "tire0", name: "GoodYear-Sport-Tire", model: "gy-sp00-19p-22p")
//        let audiwheels = [Wheel(id: "wheel0", tire: goodyear), Wheel(id: "wheel1", tire: goodyear), Wheel(id: "wheel2", tire: goodyear), Wheel(id: "wheel3", tire: goodyear)]
//        let audi = Car(id: "car0", name: "Audi S3", wheels: audiwheels)
//
//        let pirelli = Tire(id: "tire1", name: "Pirelli-Magnet-Tire", model: "pm22p00mg")
//        let bmwwheels = [Wheel(id: "wheel4", tire: pirelli), Wheel(id: "wheel5", tire: pirelli), Wheel(id: "wheel6", tire: pirelli), Wheel(id: "wheel7", tire: pirelli)]
//        let bmw = Car(id: "car1", name: "BMW M1", wheels: bmwwheels)
//
//        let cars = [audi, bmw]
//
//        do {
//            let encoded = try JSONAPIEncoder().encode(object: cars)
//            debugPrint("---------------------------------------------")
//            debugPrint(String(data: encoded, encoding: .utf8)!)
//            debugPrint("---------------------------------------------")
//            let inverse = try JSONAPIDecoder().decode([Car].self, from: encoded)
//            debugPrint("---------------------------------------------")
//            XCTAssert(cars.count == inverse.count, "Inverse serialization object should produce same object")
//        } catch {
//            XCTAssert(false, error.localizedDescription)
//        }
//    }
    
//    func testWallets() {
//
//        let wallet = Wallet(id: "w0", bitcoinWallets: [BitCoinWallet(id: "bw0"), BitCoinWallet(id: "bw0")])
//
//        do {
//
//            let encoded = try JSONAPIEncoder().encode(object: wallet)
//            printJson(data: encoded)
//
//            XCTAssertTrue(try encodingAndDecoding(toEncode: wallet), "Inverse serialization object should produce same object")
//        } catch {
//            XCTAssert(false, "Inverse serialization object should produce same object\n\n\(error.localizedDescription)")
//        }
//    }

    func testUser() {
        let user = User(id: "user0", info: "The first user", location: Location(id: "location0", region: Region(id: "region0", name: "Paris")))

        do {

            let encoded = try JSONAPIEncoder().encode(object: user)
            printJson(data: encoded)

            XCTAssertTrue(try encodingAndDecoding(toEncode: user), "Inverse serialization object should produce same object")
        } catch {
            XCTAssert(false, "Inverse serialization object should produce same object\n\n\(error.localizedDescription)")
        }
    }
    
    func encodingAndDecoding<T: Codable>(toEncode: T) throws -> Bool {
        let encoded = try JSONAPIEncoder().encode(object: toEncode)
        let decoded = try JSONAPIDecoder().decode(T.self, from: encoded)
        return try dataCompare(T.self, object1: toEncode, object2: decoded)
    }
    
    func dataCompare<T: Codable>(_ type: T.Type, object1: T, object2: T) throws -> Bool {
        let data1 = try JSONEncoder().encode(object1)
        let data2 = try JSONEncoder().encode(object2)
        return data1 == data2
    }
    
    func printJson(data: Data) {
        print(String(data: data, encoding: .utf8)!)
    }
}


