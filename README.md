# HPDB Guideline

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/shuangyu/HPPluginRepo/blob/master/The%20MIT%20License%20(MIT))&nbsp;
![Support](https://img.shields.io/badge/language-swift-orange.svg)&nbsp;
![Support](https://img.shields.io/badge/language-kotlin-orange.svg)&nbsp;
![Support](https://img.shields.io/badge/language-ReactNative-orange.svg)&nbsp;
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)&nbsp;
![Platform](https://img.shields.io/badge/platform-Android-lightgrey.svg)&nbsp;
![Platform](https://img.shields.io/badge/platform-ReactNative-lightgrey.svg)&nbsp;
[![Build Status](https://api.travis-ci.org/shuangyu/HPPluginRepo.svg?branch=master)](https://travis-ci.org/shuangyu/HPPluginRepo)

## 一、能力
+ 支持普通数据库和加密数据库
+ 支持预定义表和动态生成表
+ 支持动态扩展表(目前只支持新增字段)
+ 记录当前数据库版本号,升级逻辑需自行实现
+ 支持sync 和 async I/O

## 二、配置

*iOS默认使用非加密数据库, Android必须指定一个数据库*

**示例 :**

***iOS :***

一、创建预定义的表结构
```
@objc(XSYOfflineOperation)
class XSYOfflineOperation: NSObject, IHPDBTableDesc {
  
  static var tableName: String = "XSYOfflineOperation"
  static var tableSchema: Array<HPDBColumnDesc> = [
    HPDBColumnDesc(name: "opType", type: .text, nullable: false),
    HPDBColumnDesc(name: "tryTime", type: .integer, defaultVal: 3),
    HPDBColumnDesc(name: "status", type: .integer, defaultVal: 0),
    HPDBColumnDesc(name: "id", type: .text, nullable: false),
    HPDBColumnDesc(name: "createTime", type: .integer, nullable: false), // time interval
    HPDBColumnDesc(name: "barrier", type: .integer, defaultVal: 0),
    HPDBColumnDesc(name: "dependency", type: .text),  // another operation's id val
    HPDBColumnDesc(name: "boData", type: .text),
    HPDBColumnDesc(name: "boType", type: .text),
    HPDBColumnDesc(name: "rnWho", type: .text),  // breeze fwk specified clm
    HPDBColumnDesc(name: "rnWhich", type: .text) // breeze fwk specified clm
  ]
}
```
二、配置自定义加密数据库并初始化预定义的XSYOfflineOperation表
```
private let _db = try! HPDB(encryptionKey: "123456789")
HPDBContext.default.db = _db

...

XSYOfflineOperation.tableName.db_createTable(with: XSYOfflineOperation.tableSchema)
```

三、根据bo schema并动态生成表
```
...
// db_name: bo name
// db_fields: schema信息解析成的Array<HPDBColumnDesc>
db_name.db_createTable(with: db_fields)
...

```

***Android :***

一、初始化DB(required)
```
 HPDBContext.db = HPDBAdapter(MainApplication.context!!, encryptionKey = "123456789")
```

其他和iOS一致

## 三、API(iOS、Android完全一致)

+ 参数此处不做描述, IDE中会自动补全
+ 每个API都有多种变种, 会根据传入的参数不同自行判定
+ 对于某些比较危险的或者不常用的操作不提供shortcut API,例如删除表、查询表的schema,但仍可自行调用db执行sql
    + iOS: HPDBSQL
    + Android: HPDBSQLBuilder

API           |DESC
--------------|------------------
db_findAll    |查找符合条件的记录
db_findFirst  |查找符合条件的第一条记录
db_createTable|创建表
db_insert     |插入一条或多条记录
db_update     |更新某条记录
db_delete     |删除符合条件的记录

**async示例 :**

***iOS :***
```
// async
boType.db_insert(records: s_data ) {_,_ in}
// sync
boType.db_insert(records: s_data )
```

***Android :***
```
// async
boType.db_insert(rs) {}
// sync
boType.db_insert(rs)
```
