//
//  SimpleKeyValueStoreTests.swift
//  SimpleKeyValueStoreTests
//
//  Created by Daniel Eggert on 12/08/2015.
//  Copyright © 2015 Daniel Eggert. All rights reserved.
//

import XCTest
@testable import SimpleKeyValueStore




class SimpleKeyValueStoreTests: XCTestCase {
    
    var databaseURL: NSURL!
    
    override func setUp() {
        super.setUp()

        databaseURL = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).URLByAppendingPathComponent("key-value-\(NSUUID().UUIDString)")
    }
    
    override func tearDown() {
        databaseURL = nil
        super.tearDown()
    }
    
    func deleteDatabaseIfExistsAtURL(fileURL: NSURL) {
        let url = fileURL.URLByAppendingPathExtension("db")
        let fm = NSFileManager.defaultManager()
        do {
            try fm.removeItemAtURL(url)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == 4 {
            // Ignore
        } catch {
            fatalError("Failed to delete database at '\(url.path)': \(error)")
        }
    }
    
    func testThatItReturnsNilWhenEmpty() {
        // Given
        deleteDatabaseIfExistsAtURL(databaseURL)
        let sut = try! dbmKeyValueStoreAtURL(databaseURL)
        
        // Then
        XCTAssertEqual(sut["1"], nil)
        XCTAssertEqual(sut["2"], nil)
    }
    
    func testThatItStoresValues() {
        // Given
        let dataA = "A".dataUsingEncoding(NSUTF8StringEncoding)
        let dataB = "B".dataUsingEncoding(NSUTF8StringEncoding)
        
        deleteDatabaseIfExistsAtURL(databaseURL)
        let sut = try! dbmKeyValueStoreAtURL(databaseURL)
        
        // When
        sut["1"] = dataA
        sut["2"] = dataB
        
        // Then
        XCTAssertEqual(sut["1"], dataA)
        XCTAssertEqual(sut["2"], dataB)
    }
    
    func testThatItUpdatesValues() {
        // Given
        let dataA = "A".dataUsingEncoding(NSUTF8StringEncoding)
        let dataB = "B".dataUsingEncoding(NSUTF8StringEncoding)
        
        deleteDatabaseIfExistsAtURL(databaseURL)
        let sut = try! dbmKeyValueStoreAtURL(databaseURL)
        
        // When
        sut["1"] = dataA
        sut["1"] = dataB
        
        // Then
        XCTAssertEqual(sut["1"], dataB)
    }
    
    func testThatItDoesNotAffectOtherValues() {
        // Given
        let dataA = "A".dataUsingEncoding(NSUTF8StringEncoding)
        let dataB = "B".dataUsingEncoding(NSUTF8StringEncoding)
        let dataC = "C".dataUsingEncoding(NSUTF8StringEncoding)
        
        deleteDatabaseIfExistsAtURL(databaseURL)
        let sut = try! dbmKeyValueStoreAtURL(databaseURL)
        
        // When
        sut["1"] = dataA
        sut["2"] = dataB
        sut["1"] = dataC
        
        // Then
        XCTAssertEqual(sut["1"], dataC)
        XCTAssertEqual(sut["2"], dataB)
    }
    
    func testThatItCanBeIteratedOver() {
        // Given
        let data = "A".dataUsingEncoding(NSUTF8StringEncoding)
        
        deleteDatabaseIfExistsAtURL(databaseURL)
        let sut = try! dbmKeyValueStoreAtURL(databaseURL)
        
        sut["1"] = data
        sut["2"] = data
        sut["3"] = data
        
        // When
        var allKeys = Set<String>()
        for key in sut {
            allKeys.insert(key)
        }
        
        // Then
        XCTAssertEqual(allKeys, Set(["1", "2", "3"]))
    }
    
    func testPerformanceOfUpdating() {
        deleteDatabaseIfExistsAtURL(databaseURL)
        let sut = try! dbmKeyValueStoreAtURL(databaseURL)
        
        var count = 0
        self.measureBlock {
            count++
            let data = NSData(bytes: &count, length: sizeof(count.dynamicType))
            sut["myKey"] = data
        }
    }
    
    func testPerformanceOfSetting() {
        deleteDatabaseIfExistsAtURL(databaseURL)
        let sut = try! dbmKeyValueStoreAtURL(databaseURL)
        
        let data = "A".dataUsingEncoding(NSUTF8StringEncoding)
        var count = 0
        self.measureBlock {
            let key = "\(count++)"
            sut[key] = data
        }
    }
    
}
