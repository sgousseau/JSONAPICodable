//
//  DictionaryExtensionTests.swift
//  JSONAPICodableTests
//
//  Created by Mohamed Hajlaoui on 31/12/2018.
//  Copyright © 2018 Chanel. All rights reserved.
//
import Foundation
import XCTest
@testable import JSONAPICodable

class DictionaryExtensionTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAttributeExpressible() {
        let jsonapi = jsonObject(jsonAPIData) as! Dictionary<String, Any>
        
        XCTAssertNotNil(jsonapi.child)
        XCTAssertNil(jsonapi.children)
        XCTAssertNotNil(jsonapi.child!.identifiers)
        XCTAssertNotNil(jsonapi.child!.attributes)
        XCTAssertFalse(jsonapi.child!.isJSONAPIAttributeExpressible)
        XCTAssertTrue(jsonapi.child!.isJSONAPIRelationExpressible)
        XCTAssertNotNil(jsonapi.meta)
        XCTAssertNotNil(jsonapi.child!.meta)
        XCTAssertNil(jsonapi.relationships)
        XCTAssertNotNil(jsonapi.included)
    }
}

fileprivate func jsonObject(_ from: String) -> Any {
    return try! JSONSerialization.jsonObject(with: from.data(using: .utf8)!, options: .allowFragments)
}

fileprivate let jsonAPIData =
"""
{
    "meta": {
        "topLevelMeta": "topMeta"
    },
    "data" : {
        "id" : "0",
        "type" : "toptypes",
        "links": {
            "self": "https://self.com"
        },
        "meta": {
            "resourceLevelMeta": "resourceMeta"
        },
        "attributes" : {
            "authorizedValue" : "authorizedValue",
            "forbiddenValue" : "forbiddenValue"
        },
        "relationships" : {
            "list": [
                {
                    "id" : "0",
                    "type" : "nestedTypes0"
                },
                {
                    "id" : "1",
                    "type" : "nestedTypes0"
                }
            ]
        }
    },
    "included": [
        {
            "type" : "nestedTypes0",
            "id" : "0",
            "attributes" : {
                "typeName" : "Nested Type 0",
                "element" : "first element of type N0"
            }
        },
        {
            "type" : "nestedTypes0",
            "id" : "1",
            "attributes" : {
                "typeName" : "Nested Type 0",
                "element" : "second element of type N0"
            }
        }
    ]
}
"""
