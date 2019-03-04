import XCTest
@testable import JSONAPICodable

class JSONAPICodableTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNestedObjects() {
        let bundle = Bundle(for: JSONAPICodableTests.self)
        let nestedObjectsData = try! String(contentsOfFile: bundle.path(forResource: "NestedObjects", ofType: "json")!).data(using: .utf8)!

        do {
            let object = try JSONAPIDecoder().decode(TopObject.self, from: nestedObjectsData)
            XCTAssertTrue(try encodingAndDecoding(toEncode: object), "Inverse serialization object should produce same object")
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
    }

    func testNestedArrays() {
        let tickets0 = Cash(id: "cash0", value: 10, count: 10)
        let tickets1 = Cash(id: "cash1", value: 5, count: 5)
        let atm = ATM(id: "atm0", name: "atm madeleine", cash: [tickets0, tickets1])

        XCTAssertTrue(try encodingAndDecoding(toEncode: atm), "Inverse serialization object should produce same object")
    }

    func testNestedArrays2() {
        let goodYear = Tire(id: "tire0", name: "GoodYear-Sport-Tire", model: "gy-sp00-19p-22p")
        let wheels = [Wheel(id: "wheel0", tire: goodYear), Wheel(id: "wheel1", tire: goodYear), Wheel(id: "wheel2", tire: goodYear), Wheel(id: "wheel3", tire: goodYear)]
        let audi = Car(id: "car0", name: "Audi S3", wheels: wheels)

        XCTAssertTrue(try encodingAndDecoding(toEncode: audi), "Inverse serialization object should produce same object")
    }
    
    func testArrays() {
        let goodyear = Tire(id: "tire0", name: "GoodYear-Sport-Tire", model: "gy-sp00-19p-22p")
        let audiwheels = [Wheel(id: "wheel0", tire: goodyear), Wheel(id: "wheel1", tire: goodyear), Wheel(id: "wheel2", tire: goodyear), Wheel(id: "wheel3", tire: goodyear)]
        let audi = Car(id: "car0", name: "Audi S3", wheels: audiwheels)

        let pirelli = Tire(id: "tire1", name: "Pirelli-Magnet-Tire", model: "pm22p00mg")
        let bmwwheels = [Wheel(id: "wheel4", tire: pirelli), Wheel(id: "wheel5", tire: pirelli), Wheel(id: "wheel6", tire: pirelli), Wheel(id: "wheel7", tire: pirelli)]
        let bmw = Car(id: "car1", name: "BMW M1", wheels: bmwwheels)

        let cars = [audi, bmw]

        XCTAssertTrue(try encodingAndDecoding(toEncode: cars), "Inverse serialization object should produce same object")
    }
    
    func testWallets() {
        let wallet = Wallet(id: "w0", bitcoinWallets: [BitCoinWallet(id: "bw0"), BitCoinWallet(id: "bw0")])
        XCTAssertTrue(try encodingAndDecoding(toEncode: wallet), "Inverse serialization object should produce same object")
    }
    
    func testArticle() {
        //il y a une faille, on doit pouvoir extraire les links à partir des relations. Actuellement, les links d'un objet sont ceux présents dans Included ou Data du root
        let spec = """
        {
          "data": [{
            "type": "articles",
            "id": "1",
            "attributes": {
              "title": "JSON:API paints my bikeshed!"
            },
            "links": {
              "self": "http://example.com/articles/1"
            },
            "relationships": {
              "author": {
                "links": {
                  "self": "http://example.com/articles/1/relationships/author",
                  "related": "http://example.com/articles/1/author"
                },
                "data": { "type": "people", "id": "9" }
              },
              "comments": {
                "links": {
                  "self": "http://example.com/articles/1/relationships/comments",
                  "related": "http://example.com/articles/1/comments"
                },
                "data": [
                  { "type": "comments", "id": "5" },
                  { "type": "comments", "id": "12" }
                ]
              }
            }
          }],
          "included": [{
            "type": "people",
            "id": "9",
            "attributes": {
              "first-name": "Dan",
              "last-name": "Gebhardt",
              "twitter": "dgeb"
            },
            "links": {
              "self": "http://example.com/people/9"
            }
          }, {
            "type": "comments",
            "id": "5",
            "attributes": {
              "body": "First!"
            },
            "relationships": {
              "author": {
                "data": { "type": "people", "id": "2" }
              }
            },
            "links": {
              "self": "http://example.com/comments/5"
            }
          }, {
            "type": "comments",
            "id": "12",
            "attributes": {
              "body": "I like XML better"
            },
            "relationships": {
              "author": {
                "data": { "type": "people", "id": "9" }
              }
            },
            "links": {
              "self": "http://example.com/comments/12"
            }
          }]
        }
        """.data(using: .utf8)!
        
        do {
            let articles = try JSONAPIDecoder().decode([Article].self, from: spec)
            print(try encodingAndDecoding(toEncode: articles + articles))
        } catch {
            print(error)
        }
    }
    
    func testRootLinksToObjects() {
        let data = """
        {"data":[{"type":"packages","id":"12999","attributes":{"title":"UATHKG106Blolo","availableSince":"2019-01-22T16:03:56Z","quantityExpected":0,"sender":null,"recipient":null,"finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"12999"}}}},{"type":"packages","id":"12987","attributes":{"title":"Packingqa7","availableSince":"2019-01-22T13:19:16Z","quantityExpected":0,"sender":null,"recipient":null,"finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"12987"}}}},{"type":"packages","id":"13028","attributes":{"title":"LOLO10","availableSince":"2019-01-25T12:55:19Z","quantityExpected":1,"sender":null,"recipient":null,"finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"13028"}}}},{"type":"packages","id":"13005","attributes":{"title":"FAST002","availableSince":"2019-01-24T12:15:54Z","quantityExpected":28,"sender":null,"recipient":"ZURICH","finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"13005"}}}},{"type":"packages","id":"13031","attributes":{"title":"LOLO04","availableSince":"2019-01-25T13:01:05Z","quantityExpected":2,"sender":"Global DC VEMARS","recipient":"ZURICH","finalPremise":"ZURICH"},"relationships":{"status":{"data":{"type":"packageStatus","id":"13031"}}}},{"type":"packages","id":"13016","attributes":{"title":"PACK004","availableSince":"2019-01-25T11:05:41Z","quantityExpected":14,"sender":"ZURICH","recipient":"ZURICH","finalPremise":"ZURICH"},"relationships":{"status":{"data":{"type":"packageStatus","id":"13016"}}}},{"type":"packages","id":"12989","attributes":{"title":"Packingqa8","availableSince":"2019-01-22T13:46:36Z","quantityExpected":0,"sender":null,"recipient":null,"finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"12989"}}}},{"type":"packages","id":"13017","attributes":{"title":"PACK005","availableSince":"2019-01-25T11:05:41Z","quantityExpected":28,"sender":"ZURICH","recipient":null,"finalPremise":"ZURICH"},"relationships":{"status":{"data":{"type":"packageStatus","id":"13017"}}}},{"type":"packages","id":"12990","attributes":{"title":"Packingqa9","availableSince":"2019-01-22T13:54:32Z","quantityExpected":0,"sender":null,"recipient":null,"finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"12990"}}}},{"type":"packages","id":"13014","attributes":{"title":"PACK002","availableSince":"2019-01-25T11:05:41Z","quantityExpected":14,"sender":"ZURICH","recipient":"ZURICH","finalPremise":"ZURICH"},"relationships":{"status":{"data":{"type":"packageStatus","id":"13014"}}}}],"links":{"first":"/api/packings/list?page%5Bnumber%5D=0&page%5Bsize%5D=10","prev":null,"next":"/api/packings/list?page%5Bnumber%5D=1&page%5Bsize%5D=10","last":"/api/packings/list?page%5Bnumber%5D=2&page%5Bsize%5D=10"},"included":[{"type":"packageStatus","id":"12999","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T16:04:05.176Z"}},{"type":"packageStatus","id":"12987","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-22T13:19:16.162Z"}},{"type":"packageStatus","id":"13028","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T12:55:19.434Z"}},{"type":"packageStatus","id":"13005","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T09:56:52.343Z"}},{"type":"packageStatus","id":"13031","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T13:01:05.315Z"}},{"type":"packageStatus","id":"13016","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T11:05:41.681Z"}},{"type":"packageStatus","id":"12989","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-22T13:46:36.927Z"}},{"type":"packageStatus","id":"13017","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-30T10:05:11.918Z"}},{"type":"packageStatus","id":"12990","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-22T13:54:32.402Z"}},{"type":"packageStatus","id":"13014","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T11:05:41.454Z"}}]}
        """.data(using: .utf8)!
        
        do {
            let packages = try JSONAPIDecoder().decode([Package].self, from: data, option: .rootLevelLinksOverride)
            print(try encodingAndDecoding(toEncode: packages))
            if packages.first!.links == nil {
                XCTAssert(false, "Links object should not be nil because there is a root links object and .rootLevelLinksOverride option")
            }
        } catch {
            print(error)
        }
    }
    
    func testBadLinksToObjectsOption() {
        let data = """
        {"data":[{"type":"packages","id":"12999","attributes":{"title":"UATHKG106Blolo","availableSince":"2019-01-22T16:03:56Z","quantityExpected":0,"sender":null,"recipient":null,"finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"12999"}}}},{"type":"packages","id":"12987","attributes":{"title":"Packingqa7","availableSince":"2019-01-22T13:19:16Z","quantityExpected":0,"sender":null,"recipient":null,"finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"12987"}}}},{"type":"packages","id":"13028","attributes":{"title":"LOLO10","availableSince":"2019-01-25T12:55:19Z","quantityExpected":1,"sender":null,"recipient":null,"finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"13028"}}}},{"type":"packages","id":"13005","attributes":{"title":"FAST002","availableSince":"2019-01-24T12:15:54Z","quantityExpected":28,"sender":null,"recipient":"ZURICH","finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"13005"}}}},{"type":"packages","id":"13031","attributes":{"title":"LOLO04","availableSince":"2019-01-25T13:01:05Z","quantityExpected":2,"sender":"Global DC VEMARS","recipient":"ZURICH","finalPremise":"ZURICH"},"relationships":{"status":{"data":{"type":"packageStatus","id":"13031"}}}},{"type":"packages","id":"13016","attributes":{"title":"PACK004","availableSince":"2019-01-25T11:05:41Z","quantityExpected":14,"sender":"ZURICH","recipient":"ZURICH","finalPremise":"ZURICH"},"relationships":{"status":{"data":{"type":"packageStatus","id":"13016"}}}},{"type":"packages","id":"12989","attributes":{"title":"Packingqa8","availableSince":"2019-01-22T13:46:36Z","quantityExpected":0,"sender":null,"recipient":null,"finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"12989"}}}},{"type":"packages","id":"13017","attributes":{"title":"PACK005","availableSince":"2019-01-25T11:05:41Z","quantityExpected":28,"sender":"ZURICH","recipient":null,"finalPremise":"ZURICH"},"relationships":{"status":{"data":{"type":"packageStatus","id":"13017"}}}},{"type":"packages","id":"12990","attributes":{"title":"Packingqa9","availableSince":"2019-01-22T13:54:32Z","quantityExpected":0,"sender":null,"recipient":null,"finalPremise":null},"relationships":{"status":{"data":{"type":"packageStatus","id":"12990"}}}},{"type":"packages","id":"13014","attributes":{"title":"PACK002","availableSince":"2019-01-25T11:05:41Z","quantityExpected":14,"sender":"ZURICH","recipient":"ZURICH","finalPremise":"ZURICH"},"relationships":{"status":{"data":{"type":"packageStatus","id":"13014"}}}}],"links":{"first":"/api/packings/list?page%5Bnumber%5D=0&page%5Bsize%5D=10","prev":null,"next":"/api/packings/list?page%5Bnumber%5D=1&page%5Bsize%5D=10","last":"/api/packings/list?page%5Bnumber%5D=2&page%5Bsize%5D=10"},"included":[{"type":"packageStatus","id":"12999","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T16:04:05.176Z"}},{"type":"packageStatus","id":"12987","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-22T13:19:16.162Z"}},{"type":"packageStatus","id":"13028","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T12:55:19.434Z"}},{"type":"packageStatus","id":"13005","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T09:56:52.343Z"}},{"type":"packageStatus","id":"13031","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T13:01:05.315Z"}},{"type":"packageStatus","id":"13016","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T11:05:41.681Z"}},{"type":"packageStatus","id":"12989","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-22T13:46:36.927Z"}},{"type":"packageStatus","id":"13017","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-30T10:05:11.918Z"}},{"type":"packageStatus","id":"12990","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-22T13:54:32.402Z"}},{"type":"packageStatus","id":"13014","attributes":{"code":"AVAILABLE","lastUpdate":"2019-01-25T11:05:41.454Z"}}]}
        """.data(using: .utf8)!
        
        do {
            let packages = try JSONAPIDecoder().decode([Package].self, from: data, option: .objectLevelLinksOverride)
            print(try encodingAndDecoding(toEncode: packages))
            if packages.first!.links != nil {
                XCTAssert(false, "Links object should be nil because there is no object level links object and .objectLevelLinksOverride option")
            }
        } catch {
            print(error)
        }
    }
    
    func encodingAndDecoding<T: Codable>(toEncode: T) throws -> Bool {
        let encoded = try JSONAPIEncoder().encode(toEncode)
        let decoded = try JSONAPIDecoder().decode(T.self, from: encoded)
        return try dataCompare(T.self, object1: toEncode, object2: decoded)
    }
    
    func dataCompare<T: Codable>(_ type: T.Type, object1: T, object2: T) throws -> Bool {
        let data1 = try JSONEncoder().encode(object1)
        let data2 = try JSONEncoder().encode(object2)
        return data1 == data2
    }
    
    func printJson(object: Any) {
        do {
            print(String(data: try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted), encoding: .utf8)!)
        } catch {
            print(error)
        }
    }
    
    func printJson(data: Data) {
        print(String(data: data, encoding: .utf8)!)
    }
}


