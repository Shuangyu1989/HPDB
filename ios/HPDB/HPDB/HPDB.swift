//
//  HPDB.swift
//  DBTest
//
//  Created by rkhd on 2018/7/3.
//  Copyright © 2018 rkhd. All rights reserved.
//

import Foundation

public enum HPDBColumnType: String {
    case integer = "integer"
    case text = "text"
    case real = "real"
    case none = "none"
}

public protocol IHPDBTableDesc {
    static var tableName: String { get }
    static var tableSchema: Array<HPDBColumnDesc> { get }
}

extension Array where Element: IHPDBColumn {
    subscript(columnName: String) -> HPDBColumnType? {
        for e in self {
            if e.name == columnName {
                return e.type
            }
        }
        return nil
    }
}

protocol IHPDBColumn {
    var name: String { get set }
    var type: HPDBColumnType { get set }
    var primaryKey: Bool { get set }
    var autoIncrement: Bool { get set }
    var nullable: Bool { get set }
    var defaultVal: Any? { get set }
}


public struct HPDBColumnDesc: IHPDBColumn {
    public var name: String
    public var type: HPDBColumnType
    public var primaryKey = false
    public var autoIncrement = false
    public var nullable = true
    public var defaultVal: Any? = nil
    
    public init(name: String,
         type: String,
         primaryKey: Bool = false,
         autoIncrement: Bool = false,
         nullable: Bool = true,
         defaultVal: Any? = nil)
    {
        self.init(name: name,
                  type: HPDBColumnDesc.sqliteType(of: type))
    }
    
    public init(name: String,
         type: HPDBColumnType,
         primaryKey: Bool = false,
         autoIncrement: Bool = false,
         nullable: Bool = true,
         defaultVal: Any? = nil)
    {
        self.name = name
        self.type = type
        self.primaryKey = primaryKey
        self.autoIncrement = autoIncrement
        self.nullable = nullable
        self.defaultVal = defaultVal
    }
    
    public func toSql() -> String {
        var sql = "\(self.name) \(self.type.rawValue)"
        
        if self.primaryKey {
            sql += " PRIMARY KEY"
        }
        
        if self.autoIncrement {
            sql += " AUTOINCREMENT"
        }
        
        if !self.nullable {
            sql += " NOT NULL"
        }
        
        if self.defaultVal != nil {
            sql += " DEFAULT \(self.defaultVal!)"
        }
        return sql
    }
    
    public static func sqliteType(of type: String) -> HPDBColumnType {
        switch type.lowercased() {
        case "long", "integer", "short", "boolean", "interger", "date":
            return .integer
        case "string", "text", "object":
            return .text
        case "float", "double", "real":
            return .real
        default:
            return .text
        }
    }
}

public class HPDB {
    public typealias AnyDic = Dictionary<String, Any>
    public typealias StringDic = Dictionary<String, String>
    public typealias AnyArr = Array<Any>
    public typealias StringArr = Array<String>
    public typealias HPDBCallbackBlock = (DBError?, Array<AnyDic>?) -> Void
    public typealias HPDBOneRecordCallbackBlock = (DBError?, AnyDic?) -> Void
    
    public enum DBError: Error {
        case initFailed
        case sqlFailed
        case invalidParams
    }
    public static let _default_db_name = "brz_app"
    
    private var _exec_queue: FMDatabaseQueue?
    private var _encryption_key: String?
    private let _db_name: String
    private let _plain_db_path: String
    private let _encrypted_db_path: String
    private let _db_file_path: String
    public var schemaCache = [:] as Dictionary<String, Array<HPDBColumnDesc>>
    
    public init(name: String = _default_db_name, encryptionKey: String? = nil) throws {
        _encryption_key = encryptionKey
        _db_name = name
        
        _plain_db_path = "\(NSHomeDirectory())/Library/\(_db_name).sqlite"
        _encrypted_db_path = "\(NSHomeDirectory())/Library/\(_db_name)_encrypted.sqlite"
        _db_file_path = encryptionKey == nil ? _plain_db_path : _encrypted_db_path
        
        print("database file path: \(_db_file_path)")
        
        if _encryption_key != nil && !FileManager.default.fileExists(atPath: _encrypted_db_path)
        {
            // need to encrypt db if not encrypted yet
            encryptDB()
        }
        guard let q = FMDatabaseQueue.init(path: _db_file_path) else {
            throw DBError.initFailed
        }
        _exec_queue = q
    }
    
    private func encryptDB() {
        FileManager.default.createFile(atPath: _encrypted_db_path, contents: nil, attributes: nil)
        var rc: Int32
        var db: OpaquePointer? = nil
        var stmt: OpaquePointer? = nil
        let password: String = _encryption_key!
        rc = sqlite3_open(":memory:", &db)
        if (rc != SQLITE_OK) {
            let errmsg = String(cString: sqlite3_errmsg(db))
            NSLog("Error opening database: \(errmsg)")
            return
        }
        rc = sqlite3_key(db, password, Int32(password.utf8CString.count))
        if (rc != SQLITE_OK) {
            let errmsg = String(cString: sqlite3_errmsg(db))
            NSLog("Error setting key: \(errmsg)")
        }
        rc = sqlite3_prepare(db, "PRAGMA cipher_version;", -1, &stmt, nil)
        if (rc != SQLITE_OK) {
            let errmsg = String(cString: sqlite3_errmsg(db))
            NSLog("Error preparing SQL: \(errmsg)")
        }
        rc = sqlite3_step(stmt)
        if (rc == SQLITE_ROW) {
            NSLog("cipher_version: %s", sqlite3_column_text(stmt, 0))
        } else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            NSLog("Error retrieiving cipher_version: \(errmsg)")
        }
        sqlite3_finalize(stmt)
        sqlite3_close(db)
    }
    
    @discardableResult
    public func exec(query sql: String) -> Array<AnyDic>? {
        let db = FMDatabase.init(path: _db_file_path)
        var result = Array<AnyDic>()
        
        guard db.open() else {
            return nil
        }
        if let key = _encryption_key {
            db.setKey(key)
        }
        
        db.beginTransaction()
        do {
            let ret = try db.executeQuery(sql, values: nil)
            while ret.next() {
                result.append(ret.resultDictionary as! AnyDic)
            }
            db.commit()
        } catch {
            db.rollback()
        }
        db.close()
        return result.count > 0 ? result : nil
    }
    
    @discardableResult
    public func exec(update sql: String) -> Bool {
        
        let db = FMDatabase.init(path: _db_file_path)
        guard db.open() else {
            return false
        }
        if let key = _encryption_key {
            db.setKey(key)
        }
        db.beginTransaction()
        let ret = db.executeStatements(sql)
        if ret {
            db.commit()
        } else {
            db.rollback()
        }
        db.close()
        return ret
    }
    
    
    public func execInBackground(query sql: String, _ callback: HPDBCallbackBlock? = nil) {
        _exec_queue?.inTransaction { db, rollback in
            if let key = _encryption_key {
                db.setKey(key)
            }
            do {
                var result = Array<AnyDic>()
                let ret = try db.executeQuery(sql, values: nil)
                while ret.next() {
                    result.append(ret.resultDictionary as! AnyDic)
                }
                if let cb = callback {
                    DispatchQueue.main.async {
                        cb(nil, result)
                    }
                }
            } catch {
                rollback.pointee = true
                if let cb = callback {
                    DispatchQueue.main.async {
                        cb(DBError.sqlFailed, nil)
                    }
                }
            }
        }
    }
    
    public func execInBackground(update sql: String, _ callback: HPDBCallbackBlock? = nil) {
        _exec_queue?.inTransaction { db, rollback in
            if let key = _encryption_key {
                db.setKey(key)
            }
            let ret = db.executeStatements(sql)
            if !ret {
                rollback.pointee = true
                if let cb = callback {
                    DispatchQueue.main.async {
                        cb(DBError.sqlFailed, nil)
                    }
                }
            } else {
                if let cb = callback {
                    DispatchQueue.main.async {
                        cb(nil, nil)
                    }
                }
            }
        }
    }
    
    public func schema(of table: String) -> Array<HPDBColumnDesc>? {
        var schema = schemaCache[table]
        if schema == nil { // init cache
            schema = Array<HPDBColumnDesc>()
            let db = FMDatabase.init(path: _db_file_path)
            guard db.open() else {
                return nil
            }
            if let key = _encryption_key {
                db.setKey(key)
            }
            guard let ret = try? db.executeQuery(schemaSql(of: table), values: nil) else {
                db.close()
                return nil
            }
            while ret.next() {
                let dic = ret.resultDictionary as! AnyDic
                schema!.append(HPDBColumnDesc(name: dic["name"] as! String, type: dic["type"] as! String))
            }
            if(schema!.count > 0) { // fix issue: db not exist will return empty array
                schemaCache[table] = schema!
            } else {
                schema = nil
            }
            db.close()
        }
        return schema
    }
}
