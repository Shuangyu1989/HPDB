//
//  StringDBExt.swift
//  DBTest
//
//  Created by rkhd on 2018/7/5.
//  Copyright © 2018 rkhd. All rights reserved.
//

import Foundation

public extension String {
  public var tbl_name: String {
    return self.uppercased()
  }
  
  public func db_columnValidation(records: Array<HPDB.AnyDic>) -> Array<HPDB.AnyDic>? {
    
    guard let schemaInfo = HPDBContext.default.db!.schema(of: self.tbl_name) else {
      return nil
    }
    var result = Array<HPDB.AnyDic>()
    
    for r in records {
      var validR = HPDB.AnyDic()
      for key in r.keys {
        if schemaInfo[key] == nil {
          continue
        }
        validR[key] = r[key]
      }
      result.append(validR)
    }
    
    return result.count > 0 ? result : nil
  }
}

// retrieve ext.
public extension String {
  
  /****************************** async ******************************/
  
  public func db_findAll(by attr: String? = nil,
                  with value: Any? = nil,
                  columns: Array<String>? = nil,
                  orderBy column: String? = nil,
                  ascending: Bool = true,
                  limit: Int? = nil,
                  offset: Int = 0,
                  _ callback: @escaping HPDB.HPDBCallbackBlock)
  {
    var condition: String? = nil
    if attr != nil {
      condition = "\(attr!) = \(sqlValClean(value))"
    }
    self.db_findAll(with: columns,
                    where: condition,
                    orderBy: column,
                    ascending: ascending,
                    limit: limit,
                    offset: offset,
                    callback)
  }
  
  // pattern:
  // The percent sign % wildcard matches any sequence of zero or more characters.
  // The underscore _ wildcard matches any single character.
  public func db_findAll(by attr: String,
                  like pattern: String,
                  columns: Array<String>? = nil,
                  orderBy column: String? = nil,
                  ascending: Bool = true,
                  limit: Int? = nil,
                  offset: Int = 0,
                  _ callback: @escaping HPDB.HPDBCallbackBlock)
  {
    let condition = "\(attr) LIKE \"\(pattern)\""
    
    self.db_findAll(with: columns,
                    where: condition,
                    orderBy: column,
                    ascending: ascending,
                    limit: limit,
                    offset: offset,
                    callback)
  }
  
  public func db_findFirst(by attr: String? = nil,
                    with value: Any? = nil,
                    columns: Array<String>? = nil,
                    orderBy column: String? = nil,
                    ascending: Bool = true,
                    _ callback: @escaping HPDB.HPDBOneRecordCallbackBlock)
  {
    
    var condition: String? = nil
    if attr != nil {
      condition = "\(attr!) = \(sqlValClean(value))"
    }
    self.db_findAll(with: columns,
                    where: condition,
                    orderBy: column,
                    ascending: ascending,
                    limit: 1,
                    offset: 0) { (err, ret) in
                      if ret != nil && ret!.count > 0 {
                        callback(err, ret![0])
                      } else {
                        callback(err, nil)
                      }
    }
  }
  
  public func db_findAll(with columns: Array<String>? = nil,
                  where condition: String? = nil,
                  orderBy column: String? = nil,
                  ascending: Bool = true,
                  limit: Int? = nil,
                  offset: Int = 0,
                  _ callback: @escaping HPDB.HPDBCallbackBlock)
  {
    let sql = querySql(with: self.tbl_name,
                       columns: columns,
                       where: condition,
                       orderBy: column,
                       ascending: ascending,
                       limit: limit,
                       offset: offset)
    
    assert(HPDBContext.default.db != nil, "db not found")
    HPDBContext.default.db!.execInBackground(query: sql, callback)
  }

  public func db_findAll(columns: Dictionary<String, Array<String>>,
                  joins: Dictionary<String, HPDB.StringDic>,
                  where condition: String? = nil,
                  orderBy column: String? = nil,
                  ascending: Bool = true,
                  limit: Int? = nil,
                  offset: Int = 0,
                  _ callback: @escaping HPDB.HPDBCallbackBlock)
  {
    let sql = innerJoinSql(with: self.tbl_name,
                           columns: columns,
                           joins: joins,
                           where: condition,
                           orderBy: column,
                           ascending: ascending,
                           limit: limit,
                           offset: offset)
    assert(HPDBContext.default.db != nil, "db not found")
    HPDBContext.default.db!.execInBackground(query: sql, callback)
  }
  
  /****************************** sync ******************************/
  
  public func db_findAll(by attr: String? = nil,
                  with value: Any? = nil,
                  columns: Array<String>? = nil,
                  orderBy column: String? = nil,
                  ascending: Bool = true,
                  limit: Int? = nil,
                  offset: Int = 0) -> Array<HPDB.AnyDic>?
  {
    var condition: String? = nil
    if attr != nil {
      condition = "\(attr!) = \(sqlValClean(value))"
    }
    return self.db_findAll(with: columns,
                    where: condition,
                    orderBy: column,
                    ascending: ascending,
                    limit: limit,
                    offset: offset)
  }
  
  // pattern:
  // The percent sign % wildcard matches any sequence of zero or more characters.
  // The underscore _ wildcard matches any single character.
  public func db_findAll(by attr: String,
                  like pattern: String,
                  columns: Array<String>? = nil,
                  orderBy column: String? = nil,
                  ascending: Bool = true,
                  limit: Int? = nil,
                  offset: Int = 0) -> Array<HPDB.AnyDic>?
  {
    let condition = "\(attr) LIKE \"\(pattern)\""
    
    return self.db_findAll(with: columns,
                    where: condition,
                    orderBy: column,
                    ascending: ascending,
                    limit: limit,
                    offset: offset)
  }
  
  public func db_findFirst(by attr: String? = nil,
                    with value: Any? = nil,
                    columns: Array<String>? = nil,
                    orderBy column: String? = nil,
                    ascending: Bool = true) -> HPDB.AnyDic?
  {
    
    var condition: String? = nil
    if attr != nil {
      condition = "\(attr!) = \(sqlValClean(value))"
    }
    let ret = self.db_findAll(with: columns,
                    where: condition,
                    orderBy: column,
                    ascending: ascending,
                    limit: 1,
                    offset: 0)
    
    return (ret != nil && ret!.count > 0) ? ret![0] : nil
  }
  
  public func db_findAll(with columns: Array<String>? = nil,
                  where condition: String? = nil,
                  orderBy column: String? = nil,
                  ascending: Bool = true,
                  limit: Int? = nil,
                  offset: Int = 0) -> Array<HPDB.AnyDic>?
  {
    let sql = querySql(with: self.tbl_name,
                       columns: columns,
                       where: condition,
                       orderBy: column,
                       ascending: ascending,
                       limit: limit,
                       offset: offset)
    
    assert(HPDBContext.default.db != nil, "db not found")
    return HPDBContext.default.db!.exec(query: sql)
  }
  
  public func db_findAll(columns: Dictionary<String, Array<String>>,
                  joins: Dictionary<String, HPDB.StringDic>,
                  where condition: String? = nil,
                  orderBy column: String? = nil,
                  ascending: Bool = true,
                  limit: Int? = nil,
                  offset: Int = 0) -> Array<HPDB.AnyDic>?
  {

    let sql = innerJoinSql(with: self.tbl_name,
                           columns: columns,
                           joins: joins,
                           where: condition,
                           orderBy: column,
                           ascending: ascending,
                           limit: limit,
                           offset: offset)
    assert(HPDBContext.default.db != nil, "db not found")
    return HPDBContext.default.db!.exec(query: sql)
  }
}

// create ext.
public extension String {
  
  /****************************** async ******************************/
  
  public func db_createTable(with fields:Array<HPDBColumnDesc>,
                      _ callback: @escaping HPDB.HPDBCallbackBlock) {
    let sql = tableCreateSql(with: self.tbl_name, and: fields)
    assert(HPDBContext.default.db != nil, "db not found")
    HPDBContext.default.db!.execInBackground(update: sql, callback)
  }
  
  public func db_insert(records: Array<HPDB.AnyDic>,
                 _ callback: @escaping HPDB.HPDBCallbackBlock) {
    
    guard let rs = db_columnValidation(records: records) else {
      callback(HPDB.DBError.invalidParams, nil)
      return
    }
    let sql = batchInsertSql(with: self.tbl_name, and: rs)
    
    assert(HPDBContext.default.db != nil, "db not found")
    HPDBContext.default.db!.execInBackground(update: sql, callback)
  }
  
  public func db_insert(record: HPDB.AnyDic,
                 _ callback: @escaping HPDB.HPDBCallbackBlock) {
    
    guard let rs = db_columnValidation(records: [record]) else {
      callback(HPDB.DBError.invalidParams, nil)
      return
    }
    
    let sql = insertSql(with: self.tbl_name, and: rs[0])
    assert(HPDBContext.default.db != nil, "db not found")
    HPDBContext.default.db!.execInBackground(update: sql, callback)
  }
  
  /****************************** sync ******************************/
  @discardableResult
  public func db_createTable(with fields:Array<HPDBColumnDesc>) -> Bool {
    let sql = tableCreateSql(with: self.tbl_name, and: fields)
    assert(HPDBContext.default.db != nil, "db not found")
    return HPDBContext.default.db!.exec(update: sql)
  }
  @discardableResult
  public func db_insert(records: Array<HPDB.AnyDic>) -> Bool {
    guard let rs = db_columnValidation(records: records) else {
      return false
    }
    let sql = batchInsertSql(with: self.tbl_name, and: rs)
    assert(HPDBContext.default.db != nil, "db not found")
    return HPDBContext.default.db!.exec(update: sql)
  }
  @discardableResult
  public func db_insert(record: HPDB.AnyDic) -> Bool {
    
    guard let rs = db_columnValidation(records: [record]) else {
      return false
    }
    
    let sql = insertSql(with: self.tbl_name, and: rs[0])
    assert(HPDBContext.default.db != nil, "db not found")
    return HPDBContext.default.db!.exec(update: sql)
  }
}

// update ext.
public extension String {
  
  /****************************** async ******************************/
  
  public func db_update(record: HPDB.AnyDic,
                 by attr: String,
                 with value: Any,
                 _ callback: @escaping HPDB.HPDBCallbackBlock)
  {
    
    guard let rs = db_columnValidation(records: [record]) else {
      callback(HPDB.DBError.invalidParams, nil)
      return
    }
    
    let condition = "\(attr) = \(sqlValClean(value))"
    let sql = updateSql(with: self.tbl_name, where: condition, data: rs[0])
    assert(HPDBContext.default.db != nil, "db not found")
    HPDBContext.default.db!.execInBackground(update: sql, callback)
  }
  
  /****************************** sync ******************************/
  
  @discardableResult
  public func db_update(record: HPDB.AnyDic,
                 by attr: String,
                 with value: Any) -> Bool
  {
    guard let rs = db_columnValidation(records: [record]) else {
      return false
    }
    
    let condition = "\(attr) = \(sqlValClean(value))"
    let sql = updateSql(with: self.tbl_name, where: condition, data: rs[0])
    assert(HPDBContext.default.db != nil, "db not found")
    return HPDBContext.default.db!.exec(update: sql)
  }
}

// delete ext.
public extension String {
  
  /****************************** async ******************************/
  
  public func db_delete(by attr: String,
                 with value: Any,
                 columns: Array<String>? = nil,
                 orderBy column: String? = nil,
                 ascending: Bool = true,
                 limit: Int? = nil,
                 offset: Int = 0,
                 _ callback: @escaping HPDB.HPDBCallbackBlock) {
    
    let condition = "\(attr) = \(sqlValClean(value))"
    self.db_delete(where: condition,
                   orderBy: column,
                   ascending: ascending,
                   limit: limit,
                   offset: offset,
                   callback)
  }
  
  public func db_delete(by attr: String,
                 like pattern: String,
                 columns: Array<String>? = nil,
                 orderBy column: String? = nil,
                 ascending: Bool = true,
                 limit: Int? = nil,
                 offset: Int = 0,
                 _ callback: @escaping HPDB.HPDBCallbackBlock)
  {
    let condition = "\(attr) LIKE \"\(pattern)\""
    self.db_delete(where: condition,
                   orderBy: column,
                   ascending: ascending,
                   limit: limit,
                   offset: offset,
                   callback)
  }
  
  public func db_delete(where condition: String,
                 orderBy column: String? = nil,
                 ascending: Bool = true,
                 limit: Int? = nil,
                 offset: Int = 0,
                 _ callback: @escaping HPDB.HPDBCallbackBlock)
  {
    let sql = deleteSql(with: self.tbl_name,
                        where: condition,
                        orderBy: column,
                        ascending: ascending,
                        limit: limit,
                        offset: offset)
    assert(HPDBContext.default.db != nil, "db not found")
    HPDBContext.default.db!.execInBackground(update: sql, callback)
  }
  
  /****************************** sync ******************************/
  // dangerous operation! won't implement this shortcut
//  @discardableResult
//  public func db_deleteTable() {
//
//  }
  @discardableResult
  public func db_delete(by attr: String,
                 with value: Any,
                 orderBy column: String? = nil,
                 ascending: Bool = true,
                 limit: Int? = nil,
                 offset: Int = 0) -> Bool
  {
    
    let condition = "\(attr) = \(sqlValClean(value))"
    return self.db_delete(where: condition,
                   orderBy: column,
                   limit: limit,
                   offset: offset)
    
  }
  @discardableResult
  public func db_delete(by attr: String,
                 like pattern: String,
                 orderBy column: String? = nil,
                 ascending: Bool = true,
                 limit: Int? = nil,
                 offset: Int = 0) -> Bool
  {
    let condition = "\(attr) LIKE \"\(pattern)\""
    return self.db_delete(where: condition,
                   orderBy: column,
                   limit: limit,
                   offset: offset)
  }
  @discardableResult
  public func db_delete(where condition: String,
                 orderBy column: String? = nil,
                 ascending: Bool = true,
                 limit: Int? = nil,
                 offset: Int = 0)  -> Bool
  {
    let sql = deleteSql(with: self.tbl_name,
                        where: condition,
                        orderBy: column,
                        ascending: ascending,
                        limit: limit,
                        offset: offset)
    assert(HPDBContext.default.db != nil, "db not found")
    return HPDBContext.default.db!.exec(update: sql)
  }
}
