//
//  M A R S H A L
//
//       ()
//       /\
//  ()--'  '--()
//    `.    .'
//     / .. \
//    ()'  '()
//
//

import XCTest
@testable import Marshal

class MarshalTests: XCTestCase {
    
    let object: MarshalDictionary = ["bigNumber": NSNumber(value: 10_000_000_000_000 as Int64),
                                     "foo": 2,
                                     "str": "Hello, World!",
                                     "array": [1,2,3,4,7],
                                     "object": ["foo": 3, "str": "Hello, World!"],
                                     "url": "http://apple.com",
                                     "junk": "garbage",
                                     "urls": ["http://apple.com", "http://github.com"]]
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBasics() {
        self.measure {
            let str: String = try! self.object.value(for: "str")
            XCTAssertEqual(str, "Hello, World!")
            //    var foo1: String = try object.value(for: "foo")
            let foo2: Int = try! self.object.value(for: "foo")
            XCTAssertEqual(foo2, 2)
            let bigNumber: Int64 = try! self.object.value(for: "bigNumber")
            XCTAssertEqual(bigNumber, 10_000_000_000_000)
            let foo3: Int? = try! self.object.value(for: "foo")
            XCTAssertEqual(foo3, 2)
            let foo4: Int? = try! self.object.value(for: "bar")
            XCTAssertEqual(foo4, .none)
            let arr: [Int] = try! self.object.value(for: "array")
            XCTAssert(arr.count == 5)
            let obj: JSONObject = try! self.object.value(for: "object")
            XCTAssert(obj.count == 2)
            let innerfoo: Int = try! obj.value(for: "foo")
            XCTAssertEqual(innerfoo, 3)
            let innerfoo2: Int = try! self.object.value(for: "object.foo")
            XCTAssertEqual(innerfoo2, 3)
            let url:URL = try! self.object.value(for: "url")
            XCTAssertEqual(url.host, "apple.com")
            
            let expectation = self.expectation(description: "error")
            do {
                let _:Int? = try self.object.value(for: "junk")
            }
            catch {
                let jsonError = error as! Marshal.MarshalError
                expectation.fulfill()
                guard case Marshal.MarshalError.typeMismatchWithKey = jsonError else {
                    XCTFail("shouldn't get here")
                    return
                }
            }
            
            let urls:[URL] = try! self.object.value(for: "urls")
            XCTAssertEqual(urls.first!.host, "apple.com")
            
            self.waitForExpectations(timeout: 1, handler: nil)
        }
    }
    
    func testOptionals() {
        var str: String = try! object <| "str"
        XCTAssertEqual(str, "Hello, World!")
        
        var optStr: String? = try! object <| "str"
        XCTAssertEqual(optStr, "Hello, World!")
        
        optStr = try! object <| "not found"
        XCTAssertEqual(optStr, .none)
        
        let ra: [Int] = try! object <| "array"
        XCTAssertEqual(ra[0], 1)
        
        var ora: [Int]? = try! object <| "array"
        XCTAssertEqual(ora![0], 1)
        
        ora = try! object <| "no key"
        XCTAssertNil(ora)
        
        let ex = self.expectation(description: "not found")
        do {
            str = try object <| "not found"
        }
        catch {
            if case Marshal.MarshalError.keyNotFound = error {
                ex.fulfill()
            }
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testErrors() {
        var expectation = self.expectation(description: "not found")
        let str: String = try! self.object.value(for: "str")
        XCTAssertEqual(str, "Hello, World!")
        do {
            let _:Int = try object.value(for: "no key")
        }
        catch {
            if case Marshal.MarshalError.keyNotFound = error {
                expectation.fulfill()
            }
        }
        
        expectation = self.expectation(description: "key mismatch")
        do {
            let _:Int = try object.value(for: "str")
        }
        catch {
            if case Marshal.MarshalError.typeMismatchWithKey = error {
                expectation.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testDicionary() {
        let path = Bundle(for: type(of: self)).path(forResource: "TestDictionary", ofType: "json")!
        var data = try! Data(contentsOf: URL(fileURLWithPath: path))
        var json: JSONObject = try! JSONParser.JSONObjectWithData(data)
        let url: URL = try! json.value(for: "meta.next")
        XCTAssertEqual(url.host, "apple.com")
        var people: [JSONObject] = try! json.value(for: "list")
        var person = people[0]
        let city: String = try! person.value(for: "address.city")
        XCTAssertEqual(city, "Cupertino")
        
        data = try! json.jsonData()
        
        json = try! JSONParser.JSONObjectWithData(data)
        people = try! json.value(for: "list")
        person = people[1]
        let dead = try! !person.value(for: "living")
        XCTAssertTrue(dead)
    }
    
    func testSimpleArray() {
        let path = Bundle(for: type(of: self)).path(forResource: "TestSimpleArray", ofType: "json")!
        var data = try! Data(contentsOf: URL(fileURLWithPath: path))
        var ra = try! JSONSerialization.jsonObject(with: data, options: []) as! [AnyObject]
        XCTAssertEqual(ra.first as? Int, 1)
        XCTAssertEqual(ra.last as? String, "home")
        
        data = try! ra.jsonData()
        ra = try! JSONSerialization.jsonObject(with: data, options: []) as! [AnyObject]
        XCTAssertEqual(ra.first as? Int, 1)
        XCTAssertEqual(ra.last as? String, "home")
    }
    
    func testObjectArray() {
        let path = Bundle(for: type(of: self)).path(forResource: "TestObjectArray", ofType: "json")!
        var data = try! Data(contentsOf: URL(fileURLWithPath: path))
        var ra: [JSONObject] = try! JSONParser.JSONArrayWithData(data)
        
        var obj: JSONObject = ra[0]
        XCTAssertEqual(try! obj.value(for: "n") as Int, 1)
        XCTAssertEqual(try! obj.value(for: "str") as String, "hello")
        
        data = try! ra.jsonData()
        
        ra = try! JSONParser.JSONArrayWithData(data)
        obj = ra[1]
        XCTAssertEqual(try! obj.value(for: "str") as String, "world")
    }
    
    func testNested() {
        let dict = ["type": "connected",
                    "payload": [
                        "team": [
                            "id": "teamId",
                            "name": "teamName"
                        ]
            ]
        ] as [String: Any]
        
        let teamId: String = try! dict.value(for: "payload.team.id")
        XCTAssertEqual(teamId, "teamId")
    }
    
    func testCustomObjects() {
        let path = Bundle(for: type(of: self)).path(forResource: "People", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let obj = try! JSONParser.JSONObjectWithData(data)
        let people: [Person] = try! obj.value(for: "people")
        let person: Person = try! obj.value(for: "person")
        XCTAssertEqual(people.first!.firstName, "Jason")
        XCTAssertEqual(person.firstName, "Jason")
        XCTAssertEqual(person.score, 42)
        XCTAssertEqual(people.last!.address!.city, "Cupertino")
        
        let expectation1 = expectation(description: "error test")
        do {
            let _:AgedPerson = try obj.value(for: "person")
        }
        catch {
            if case MarshalError.keyNotFound = error {
                expectation1.fulfill()
            }
        }
        
        let expectation2 = expectation(description: "array error test")
        do {
            let _:[AgedPerson] = try obj.value(for: "people")
        }
        catch {
            if case MarshalError.keyNotFound = error {
                expectation2.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    enum MyEnum: String {
        case one = "One"
        case two = "Two"
        case three = "Three"
    }
    
    enum MyIntEnum: Int {
        case one = 1
        case two = 2
    }
    
    
    func testEnum() {
        let json = ["one": "One",
                    "two": "Two",
                    "three": "Three",
                    "four": "Junk",
                    "iOne": NSNumber(value: 1),
                    "iTwo": NSNumber(value: 2)] as [String : Any]

        let one: MyEnum = try! json.value(for: "one")
        XCTAssertEqual(one, MyEnum.one)
        let two: MyEnum = try! json.value(for: "two")
        XCTAssertEqual(two, MyEnum.two)
        
        let nope: MyEnum? = try! json.value(for: "junk")
        XCTAssertEqual(nope, .none)
        
        let expectation = self.expectation(description: "enum test")
        do {
            let _: MyEnum = try json.value(for: "four")
        }
        catch {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let iOne: MyIntEnum = try! json.value(for: "iOne")
        XCTAssertEqual(iOne, MyIntEnum.one)
    }
    

    func testSet() {
        let path = Bundle(for: type(of: self)).path(forResource: "TestSimpleSet", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! JSONObject
        
        let first: Set<Int> = try! json.value(for: "first")
        XCTAssertEqual(first.count, 5)
        let second: Set<Int> = try! json.value(for: "second")
        XCTAssertEqual(second.count, 5)
        
        let nope: Set<Int>? = try! json.value(for: "junk")
        XCTAssertEqual(nope, .none)
    }
    
    func testSwiftBasicTypes() {
        // broken into two parts because it was timing out during compile time.
        let partOne: Dictionary = ["int8": NSNumber(value: 100),
                                   "int16": NSNumber(value: 32_000),
                                   "int32": NSNumber(value: 2_100_000_000 as Int32),
                                   "int64": NSNumber(value: 9_000_000_000_000_000_000 as Int64)]
        let partTwo: MarshalDictionary = ["uint8": NSNumber(value: 200),
                                          "uint16": NSNumber(value: 64_000),
                                          "uint32": NSNumber(value: 4_200_000_000 as UInt32),
                                          "uint64": NSNumber(value: 9_000_000_000_000_000_000 as UInt64),
                                          "char": "S"]

        let object: MarshalDictionary = partOne.reduce(partTwo) { r, e in var r = r; r[e.0] = e.1; return r }

        let int8: Int8 = try! object.value(for: "int8")
        XCTAssertEqual(int8, 100)
        let int16: Int16 = try! object.value(for: "int16")
        XCTAssertEqual(int16, 32_000)
        let int32: Int32 = try! object.value(for: "int32")
        XCTAssertEqual(int32, 2_100_000_000)
        let int64: Int64 = try! object.value(for: "int64")
        XCTAssertEqual(int64, 9_000_000_000_000_000_000)
        
        let uint8: UInt8 = try! object.value(for: "uint8")
        XCTAssertEqual(uint8, 200)
        let uint16: UInt16 = try! object.value(for: "uint16")
        XCTAssertEqual(uint16, 64_000)
        let uint32: UInt32 = try! object.value(for: "uint32")
        XCTAssertEqual(uint32, 4_200_000_000)
        let uint64: UInt64 = try! object.value(for: "uint64")
        XCTAssertEqual(uint64, 9_000_000_000_000_000_000)

        let char: Character = try! object.value(for: "char")
        XCTAssertEqual(char, "S")
    }

    func testValueErrors() {
        do {
            let _ = try Int16.value(from: "not an int")
            XCTFail("Expected an error to be thrown")
        } catch {
            if case let Marshal.MarshalError.typeMismatch(expected: expected, actual: actual) = error {
                XCTAssertEqual("\(expected)", "Int16")
                XCTAssertEqual("\(actual)", "String")
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    func testMarshalingSwiftValues() {
        let object: MarshalDictionary = [
            "string": "A String",
            "truth": true,
            "missing": NSNull(),
            "small": 2,
            "medium": 66_000,
            "large": 4_200_000_000,
            "huge": 9_000_000_000_000_000_000,
            "decimal": 1.2,
            "array": [ "a", "b", "c" ],
            "nested": [
                "key": "value"
            ]
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [])
            let result = try JSONParser.JSONObjectWithData(data)
            let string: String = try result <| "string"
            let truth: Bool = try result <| "truth"
            let missing: String? = try result <| "missing"
            let small: Int = try result <| "small"
            let medium: Int = try result <| "medium"
            let large: Int = try result <| "large"
            let huge: Int = try result <| "huge"
            let decimal: Float = try result <| "decimal"
            let array: [String] = try result <| "array"
            let nested: [String:Any] = try result <| "nested"

            XCTAssertEqual(string, "A String")
            XCTAssertEqual(truth, true)
            XCTAssertNil(missing)
            XCTAssertEqual(small, 2)
            XCTAssertEqual(medium, 66_000)
            XCTAssertEqual(large, 4_200_000_000)
            XCTAssertEqual(huge, 9_000_000_000_000_000_000)
            XCTAssertEqual(decimal, 1.2)
            XCTAssertEqual(array, [ "a", "b", "c" ])
            XCTAssertEqual(nested as! [String:String], [ "key": "value" ])
        } catch {
            XCTFail("Error converting MarshalDictionary: \(error)")
        }
    }

}

private struct Address: Unmarshaling {
    let street:String
    let city:String
    init(object json: MarshaledObject) throws {
        street = try json.value(for: "street")
        city = try json.value(for: "city")
    }
}

private struct Person: Unmarshaling {
    let firstName:String
    let lastName:String
    let score:Int
    let address:Address?
    init(object json: MarshaledObject) throws {
        firstName = try json.value(for: "first")
        lastName = try json.value(for: "last")
        score = try json.value(for: "score")
        address = try json.value(for: "address")
    }
}

private struct AgedPerson: Unmarshaling {
    var age:Int = 0
    init(object: MarshaledObject) throws {
        age = try object.value(for: "age")
    }
}
