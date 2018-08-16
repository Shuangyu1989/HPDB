//
//  HPDBExt.swift
//  DBTest
//
//  Created by rkhd on 2018/7/4.
//  Copyright © 2018 rkhd. All rights reserved.
//

import Foundation

public func sqlHeal(_ sql: String) -> String {
  return sql.replacingOccurrences(of: "<null>", with: "null")
}
public func stringValClean(val: String) -> String {
  var result = val
  result = result
    .replacingOccurrences(of: "\"", with: "\"\"")
    .replacingOccurrences(of: "\0", with: "")
  return result
}

public func isBoolNumber(num:NSNumber) -> Bool
{
  let boolID = CFBooleanGetTypeID()
  let numID = CFGetTypeID(num)
  return numID == boolID
}

public func sqlValClean(_ val: Any?) -> Any {
  let ret: Any
  if val == nil {
    ret = "null"
  } else if val is String {
    ret = "\"\(stringValClean(val: val as! String))\""
  } else if val is Dictionary<String, Any> {
    let data = try! JSONSerialization.data(withJSONObject: val!)
    let sVal = String.init(data: data, encoding: String.Encoding.utf8)!
    ret = "\"\(stringValClean(val: sVal))\""
  } else if val is Array<Any> {
    let data = try! JSONSerialization.data(withJSONObject: val!)
    let sVal = String.init(data: data, encoding: String.Encoding.utf8)!
    ret = "\"\(stringValClean(val: sVal))\""
  } else if val is NSNumber {
    if isBoolNumber(num: val as! NSNumber) {
      ret = (val as! Bool) ? 1 : 0
    } else {
      ret = val!
    }
  } else if val is Date {
    let date = (val as! Date)
    ret = date.timeIntervalSince1970
  } else {
    ret = val!
  }
  return ret
}

public func tableCreateSql(with tbl_name: String,
                    and db_clms: Array<HPDBColumnDesc> ) -> String
{
  let clms_desc = db_clms.map{ clm -> String in
    return clm.toSql()
  }.joined(separator: ",")
  let sql =  "CREATE TABLE IF NOT EXISTS \(tbl_name) (\(clms_desc))"
  print("TABLE CREATE SQL: \(sql)")
  return sql
}

public func batchInsertSql(with tbl_name: String,
                    and data: Array<HPDB.AnyDic>) -> String
{
  if data.count == 0 {
    return ""
  }
  var sql = data.map{ e -> String in
    return insertSql(with: tbl_name, and: e)
  }.joined(separator: ";")
  sql = sqlHeal(sql)
  print("BATCH INSERT SQL: \(sql)")
  return sql
}

public func insertSql(with tbl_name: String,
               and data: HPDB.AnyDic) -> String
{
  var vals = ""
  var clms = ""
  data.keys.forEach{ key in
    clms += ",\(key)"
    vals += ",\(sqlValClean(data[key]))"
  }

  clms.removeFirst()
  vals.removeFirst()
  var sql =  "INSERT INTO \(tbl_name) (\(clms)) VALUES (\(vals))"
  sql = sqlHeal(sql)
  print("INSERT SQL: \(sql)")
  return sql
}

public func deleteSql(with tbl_name: String,
               where condition: String,
               orderBy column: String? = nil,
               ascending: Bool = true,
               limit: Int? = nil,
               offset: Int = 0) -> String
{
  var sql = "DELETE FROM \(tbl_name) WHERE \(condition)"
  if let clm = column {
    sql += " ORDER BY \(clm) \(ascending ? "ASC" : "DESC")"
  }
  
  if let lim = limit {
    sql += " LIMIT \(lim) OFFSET \(offset)"
  }
  print("DELETE SQL: \(sql)")
  return sql
}

public func deleteTableSql(with tbl_name: String) -> String {
  return "DROP TABLE IF EXISTS \(tbl_name)"
}

public func updateSql(with tbl_name: String,
               where condition: String,
               data: HPDB.AnyDic) -> String
{
  
  let vals = data.keys.map{ key -> String in
    return "\(key)=\(sqlValClean(data[key]))"
  }.joined(separator: ",")
  
  var sql =  "UPDATE \(tbl_name) SET \(vals) WHERE \(condition)"
  sql = sqlHeal(sql)
  print("UPDATE SQL: \(sql)")
  return sql
}

public func querySql(with tbl_name: String,
              columns: Array<String>? = nil,
              where condition: String? = nil,
              orderBy column: String? = nil,
              ascending: Bool = true,
              limit: Int? = nil,
              offset: Int = 0) -> String {
  var fields = "*"
  if let clms = columns {
    fields = clms.joined(separator: ",")
  }

  var sql = "SELECT \(fields) FROM \(tbl_name)"
  if let c = condition {
    sql += " WHERE \(c)"
  }
  if let clm = column {
    sql += " ORDER BY \(clm) \(ascending ? "ASC" : "DESC")"
  }
  if let lim = limit {
    sql += " LIMIT \(lim) OFFSET \(offset)"
  }
  print("SELECT SQL: \(sql)")
  return sql
}

/*
 * columns:
 * {
 *  "table_name" : ["columns in this table"]
 * }
 * joins:
 * {
 *  "join_table_name" : {
 *     "eq_left_tbl_name" : "eq_left_clm_name",
 *     "eq_right_tbl_name" : "eq_right_clm_name"
 *   }
 * }
 *
 */

public func innerJoinSql(with tbl_name: String,
                  columns: Dictionary<String, Array<String>>,
                  joins: Dictionary<String, HPDB.StringDic>,
                  where condition: String? = nil,
                  orderBy column: String? = nil,
                  ascending: Bool = true,
                  limit: Int? = nil,
                  offset: Int = 0) -> String {
  
  let clms = columns.keys.map {key -> String in
    var clmsDesc = columns[key]!.reduce("") { ret, e in
      let clmDesc = "\(key).\(e) AS \(key)_\(e)"
      return "\(ret), \(clmDesc)"
    }
    clmsDesc.removeFirst()
    return clmsDesc
  }.joined(separator: ",")
  
  let join = joins.keys.map { key -> String in
    let c = joins[key]!
    let eql = (c.keys.map { it -> String in
      return "\(it).\(c[it]!)"
    }).joined(separator: "=")
    return "INNER JOIN \(key) ON \(eql)"
  }.joined(separator: " ")
  
  var sql = "SELECT \(clms) FROM \(tbl_name) \(join)"
  
  if let c = condition {
    sql += " WHERE \(c)"
  }
  
  if let clm = column {
    sql += " ORDER BY \(clm) \(ascending ? "ASC" : "DESC")"
  }
  
  if let lim = limit {
    sql += " LIMIT \(lim) OFFSET \(offset)"
  }
  
  print("SELECT SQL: \(sql)")
  return sql
}

public func schemaSql(of tbl_name: String) -> String {
  return "PRAGMA TABLE_INFO(\(tbl_name))"
}

public func addColumnSql(with tbl_name: String,
                  and columnInfos: Array<HPDBColumnDesc>) -> String {

  let clms = columnInfos.map{ clm -> String in
    return clm.toSql()
  }.joined(separator: ";")
  let sql = "ALTER TABLE \(tbl_name) ADD COLUMN \(clms)"
  print("COLUMN ADD SQL: \(sql)")
  return sql
}

public func indexSql(with tbl_name: String,
              and columns: Array<String>) -> String {
  
  let sql = columns.map{ clm -> String in
    let idx_clm_name = "\(tbl_name)_\(clm)_idx"
    return "CREATE INDEX \(idx_clm_name) ON \(tbl_name) (\(clm))"
  }.joined(separator: ";")
  print("INDEX CREAET SQL: \(sql)")
  return sql
}

public func findTableSql(with tbl_name: String) -> String {
  let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name='\(tbl_name)'"
  print("FIND TABLE SQL: \(sql)")
  return sql
}


