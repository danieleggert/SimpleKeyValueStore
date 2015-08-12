//
//  SimpleKeyValueStore.swift
//  SimpleKeyValueStore
//
//  Created by Daniel Eggert on 12/08/2015.
//  Copyright © 2015 Daniel Eggert. All rights reserved.
//

import Foundation


/// Generic key-value-store
public protocol KeyValueStore : class, SequenceType {
    typealias Key = String
    typealias Value = NSData
    
    subscript (key: Key) -> Value? { get set }
    
    typealias Generator : KeyValueStoreGeneratorType
    func generate() -> Self.Generator
}

extension KeyValueStore {
    public func deleteDataForKey(key: Key) {
        self[key] = nil
    }
}

public func dbmKeyValueStoreAtURL(URL: NSURL) throws -> DBMKeyValueStore {
    return try DBMKeyValueStore(URL: URL)
}

public protocol KeyValueStoreGeneratorType : GeneratorType {
    typealias Element = String
}



public final class DBMKeyValueStore : KeyValueStore {
    
    public enum Error : ErrorType {
        case UnableToOpen(Int32)
    }
    
    private let database: UnsafeMutablePointer<DBM>
    
    init(URL: NSURL) throws {
        database = dbm_open(URL.fileSystemRepresentation, O_RDWR |
            O_CREAT, 0x1b0)
        if database == UnsafeMutablePointer<DBM>(nilLiteral: ()) {
            throw Error.UnableToOpen(dbm_error(database))
        }
    }
    
    deinit {
        dbm_close(database)
    }
    
    public subscript (key: String) -> NSData? {
        get {
            return dataForKey(key)
        }
        set {
            setData(newValue, forKey: key)
        }
    }
    
    private func setData(data: NSData?, forKey key: String) {
        if let data = data {
            return key.withDatum { keyAsDatum in
                return data.withDatum { dataAsDatum in
                    dbm_store(database, keyAsDatum, dataAsDatum, DBM_REPLACE)
                    fsync(dbm_dirfno(database))
                }
            }
        } else {
            return key.withDatum { keyAsDatum in
                dbm_delete(database, keyAsDatum)
                fsync(dbm_dirfno(database))
            }
        }
    }
    
    private func dataForKey(key: String) -> NSData? {
        return key.withDatum { keyAsDatum -> NSData? in
            let d = dbm_fetch(database, keyAsDatum)
            if d.dptr == UnsafeMutablePointer<Void>(nilLiteral: ()) {
                return nil
            } else {
                return NSData(dbmDatum: d)
            }
        }
    }
    
    public typealias Generator = DBMKeyValueStoreGenerator
    public func generate() -> DBMKeyValueStoreGenerator {
        return DBMKeyValueStoreGenerator(store: self)
    }
}

public struct DBMKeyValueStoreGenerator : KeyValueStoreGeneratorType {
    private let store: DBMKeyValueStore
    private var didGetFirst = false
    private init(store: DBMKeyValueStore) {
        self.store = store
    }
    public mutating func next() -> String? {
        if !didGetFirst {
            didGetFirst = true
            return dbm_firstkey(store.database).toString()
        } else {
            return dbm_nextkey(store.database).toString()
        }
    }
}

extension String {
    private func withDatum<R>(@noescape block: (datum) -> R) -> R {
        let buffer = nulTerminatedUTF8
        return buffer.withUnsafeBufferPointer { ubp -> R in
            let ump = UnsafeMutablePointer<Void>(ubp.baseAddress)
            let d = datum(dptr: ump, dsize: buffer.count - 1)
            return block(d)
        }
    }
}

extension datum {
    private func toString() -> String? {
        if let data = NSData(dbmDatum: self) {
            return NSString(data: data, encoding: NSUTF8StringEncoding) as String?
        }
        return nil
    }
}

extension NSData {
    private convenience init?(dbmDatum d: datum) {
        guard d.dptr != UnsafeMutablePointer<Void>(nilLiteral: ()) else { return nil }
        self.init(bytes: d.dptr, length: d.dsize)
    }
    private func withDatum<R>(@noescape block: (datum) -> R) -> R {
        let ump = UnsafeMutablePointer<Void>(bytes)
        let d = datum(dptr: ump, dsize: length)
        return block(d)
    }
}
