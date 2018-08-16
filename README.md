# HPDB

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/shuangyu/HPPluginRepo/blob/master/The%20MIT%20License%20(MIT))&nbsp;
![Support](https://img.shields.io/badge/language-swift-orange.svg)&nbsp;
![Support](https://img.shields.io/badge/language-kotlin-orange.svg)&nbsp;
![Support](https://img.shields.io/badge/language-ReactNative-orange.svg)&nbsp;
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)&nbsp;
![Platform](https://img.shields.io/badge/platform-Android-lightgrey.svg)&nbsp;
![Platform](https://img.shields.io/badge/platform-ReactNative-lightgrey.svg)&nbsp;
[![Build Status](https://api.travis-ci.org/shuangyu/HPPluginRepo.svg?branch=master)](https://travis-ci.org/shuangyu/HPPluginRepo)


+ [Installation](https://github.com/Shuangyu1989/HPDB/wiki/Installation)
+ [Documentation](https://github.com/Shuangyu1989/HPDB/wiki/Guideline)

# Features
+ Support multiple platforms: iOS Android React-Native
+ Support both normal and encrypted db
+ Support pre-defined table schema or dynamic table schema
  + ex. schema fetch from server and create or update ur local table
+ Support dynamic change table schema
  + currently only support insert new fields
+ Support both sync and async IO

# Demos
**一、pre-define table schema**

```
// iOS
@objc(MyTask)
class MyTask: NSObject, IHPDBTableDesc {
  static var tableName: String = "MyTask"
  static var tableSchema: Array<HPDBColumnDesc> = [
    HPDBColumnDesc(name: "type", type: .text, nullable: false),
    HPDBColumnDesc(name: "tryTime", type: .integer, defaultVal: 3),
    HPDBColumnDesc(name: "status", type: .integer, defaultVal: 0),
    HPDBColumnDesc(name: "id", type: .text, nullable: false),
    HPDBColumnDesc(name: "createTime", type: .integer, nullable: false),
    HPDBColumnDesc(name: "dependency", type: .text),
    HPDBColumnDesc(name: "data", type: .text)
  ]
}

// Android
class MyTask {
    companion object {
        const val tableName = "MyTask"
        val tableSchema = arrayListOf(
                HPDBColumnDesc("type",  HPDBColumnType.TEXT, nullable = false),
                HPDBColumnDesc("tryTime",  HPDBColumnType.INTEGER, defaultVal = 3),
                HPDBColumnDesc("status",  HPDBColumnType.INTEGER, defaultVal = 0),
                HPDBColumnDesc("id",  HPDBColumnType.TEXT, nullable = false, primaryKey = true),
                HPDBColumnDesc("createTime",  HPDBColumnType.TEXT, nullable = false),
                HPDBColumnDesc("dependency",  HPDBColumnType.TEXT),
                HPDBColumnDesc("data",  HPDBColumnType.TEXT)
}
```

**二、create table**

```
// iOS
MyTask.tableName.db_createTable(with: MyTask.tableSchema)
// Android
MyTask.tableName.db_createTable(MyTask.tableSchema)
```
**二、insert**

```
  // iOS
  var rs = Array<HPDB.AnyDic>()
  for i in 0..<50 {
    var instance = [
      "type": "create",
      "id": i,
      "createTime": Date(),
      ] as [String : Any]
    rs.append(instance)
  }
  // async batch insert
  "MyTask".db_insert(records: rs) { _,_ in }
  // sync batch insert
  "MyTask".db_insert(records: rs)
  
  // Android
  var rs = arrayListOf<JSONObject>()
  for ( i in 0 until 50) {
      var jsonObj = JSONObject().apply {
          put("type", "create")
          put("id", i)
          put("createTime", Date())
          put("boData", arrayListOf("1", "2", "3"))
      }
      rs.add(jsonObj)
  }
  // async batch insert
  "MyTask".db_insert(rs) {}
  // sync batch insert
  "MyTask".db_insert(rs)
```
