package com.rkhd.breeze.hpdb

import org.json.JSONObject

fun String.db_sqlValClean(): String {
    var sb = StringBuilder()
    for (i in 0 until this.length) {
        var c = this.toCharArray()[i]
        if(c.toInt() == 0) continue
        sb.append(c)

    }
    return sb.toString()
}

fun String.tblName(): String {
    return this.toUpperCase()
}

/********************* retrieve ext. *********************/

fun String.db_findAll(byAttr: String? = null,
                      withVal: Any? = null,
                      columns: ArrayList<String>? = null,
                      orderBy: String? = null,
                      ascending: Boolean = true,
                      limit: Int? = null,
                      offset: Int = 0): ArrayList<JSONObject>? {

    var condition: String? = null
    if(byAttr != null) {
        condition = "$byAttr = ${sqlValClean(withVal)}"
    }
    return this.db_findAll(condition, columns, orderBy, ascending, limit, offset)
}

// pattern:
// The percent sign % wildcard matches any sequence of zero or more characters.
// The underscore _ wildcard matches any single character.

fun String.db_findAll(byAttr: String,
                      likePattern: String,
                      columns: ArrayList<String>? = null,
                      orderBy: String? = null,
                      ascending: Boolean = true,
                      limit: Int? = null,
                      offset: Int = 0): ArrayList<JSONObject>? {

    val condition = "$byAttr LIKE \"$likePattern\""
    return this.db_findAll(condition, columns, orderBy, ascending, limit, offset)
}

fun String.db_findAll(where: String? = null,
                      columns: ArrayList<String>? = null,
                      orderBy: String? = null,
                      ascending: Boolean = true,
                      limit: Int? = null,
                      offset: Int = 0) : ArrayList<JSONObject>? {

    val sql = HPDBSQLBuilder()
            .queryBuilder()
            .setTableName(this.tblName())
            .setCondition(where)
            .setQueryColumns(columns)
            .setOrderBy(orderBy)
            .setAscending(ascending)
            .setLimit(limit)
            .setOffset(offset)
            .build()
    assert(HPDBContext.db != null) {
        "db not found"
    }

    return HPDBContext.db!!.execQuery(sql!!)
}


fun String.db_findFirst(byAttr: String? = null,
                        withVal: Any? = null,
                        columns: ArrayList<String>? = null,
                        orderBy: String? = null,
                        ascending: Boolean = true): JSONObject?
{

    var condition: String? = null
    if (byAttr != null) {
        condition = "$byAttr = ${sqlValClean(withVal)}"
    }
    val ret = this.db_findAll(
            condition,
            columns,
            orderBy,
            ascending,
            1,
            0
    )

    if (ret != null && ret.isNotEmpty()) {
        return ret[0]
    } else {
        return null
    }
}

// async methods
fun String.db_findAll(byAttr: String? = null,
                      withVal: Any? = null,
                      columns: ArrayList<String>? = null,
                      orderBy: String? = null,
                      ascending: Boolean = true,
                      limit: Int? = null,
                      offset: Int = 0,
                      callback: HPDBCallbackBlock) {

    var condition: String? = null
    if(byAttr != null) {
        condition = "$byAttr = ${sqlValClean(withVal)}"
    }
    this.db_findAll(condition, columns, orderBy, ascending, limit, offset, callback)
}

fun String.db_findAll(byAttr: String,
                      likePattern: String,
                      columns: ArrayList<String>? = null,
                      orderBy: String? = null,
                      ascending: Boolean = true,
                      limit: Int? = null,
                      offset: Int = 0,
                      callback: HPDBCallbackBlock) {

    val condition = "$byAttr LIKE \"$likePattern\""
    this.db_findAll(condition, columns, orderBy, ascending, limit, offset, callback)
}

fun String.db_findAll(where: String? = null,
                      columns: ArrayList<String>? = null,
                      orderBy: String? = null,
                      ascending: Boolean = true,
                      limit: Int? = null,
                      offset: Int = 0,
                      callback: HPDBCallbackBlock) {

    val sql = HPDBSQLBuilder()
            .queryBuilder()
            .setTableName(this.tblName())
            .setCondition(where)
            .setQueryColumns(columns)
            .setOrderBy(orderBy)
            .setAscending(ascending)
            .setLimit(limit)
            .setOffset(offset)
            .build()

    assert(HPDBContext.db != null) {
        "db not found"
    }

    HPDBContext.db!!.execQuery(sql!!, callback)
}


fun String.db_findFirst(byAttr: String? = null,
                        withVal: Any? = null,
                        columns: ArrayList<String>? = null,
                        orderBy: String? = null,
                        ascending: Boolean = true,
                        callback: HPDBCallbackBlock)
{

    var condition: String? = null
    if (byAttr != null) {
        condition = "$byAttr = ${sqlValClean(withVal)}"
    }
    this.db_findAll(
            condition,
            columns,
            orderBy,
            ascending,
            1,
            0) {
        val ret = it as? ArrayList<JSONObject>
        if (ret != null && ret.isNotEmpty()) {
            callback(ret[0])
        } else {
            callback(null)
        }
    }
}

/********************* create ext. *********************/

fun String.db_createTable(clmDesc: ArrayList<HPDBColumnDesc>): Boolean {

    val sql = HPDBSQLBuilder()
            .tableCreateBuilder()
            .setTableName(this.tblName())
            .setColumnDesc(clmDesc)
            .build()
    return HPDBContext.db!!.execUpdate(sql!!)
}

fun String.db_insert(records: ArrayList<JSONObject>): Boolean {
    val sql = HPDBSQLBuilder()
            .batchInsertBuilder()
            .setTableName(this.tblName())
            .setRecords(records)
            .build()

    return HPDBContext.db!!.execUpdate(sql!!)
}

fun String.db_insert(record: JSONObject): Boolean {
    val sql = HPDBSQLBuilder()
            .insertBuilder()
            .setTableName(this.tblName())
            .setRecord(record)
            .build()

    assert(HPDBContext.db != null) {
        "db not found"
    }

    return HPDBContext.db!!.execUpdate(sql!!)
}

// async methods

fun String.db_createTable(clmDesc: ArrayList<HPDBColumnDesc>, callback: HPDBCallbackBlock) {

    val sql = HPDBSQLBuilder()
            .tableCreateBuilder()
            .setTableName(this.tblName())
            .setColumnDesc(clmDesc)
            .build()
    HPDBContext.db!!.execUpdate(sql!!, callback)
}

fun String.db_insert(records: ArrayList<JSONObject>, callback: HPDBCallbackBlock) {
    val sql = HPDBSQLBuilder()
            .batchInsertBuilder()
            .setTableName(this.tblName())
            .setRecords(records)
            .build()

    assert(HPDBContext.db != null) {
        "db not found"
    }

    HPDBContext.db!!.execUpdate(sql!!, callback)
}

fun String.db_insert(record: JSONObject, callback: HPDBCallbackBlock) {

    val sql = HPDBSQLBuilder()
            .insertBuilder()
            .setTableName(this.tblName())
            .setRecord(record)
            .build()

    assert(HPDBContext.db != null) {
        "db not found"
    }

    return HPDBContext.db!!.execUpdate(sql!!, callback)
}

/********************* update ext. *********************/

fun String.db_update(record: JSONObject,
                     byAttr: String,
                     withVal: Any): Boolean {

    val condition = "$byAttr = ${sqlValClean(withVal)}"
    val sql = HPDBSQLBuilder()
            .updateBuilder()
            .setTableName(this.tblName())
            .setCondition(condition)
            .setRecord(record)
            .build()

    assert(HPDBContext.db != null) {
        "db not found"
    }

    return HPDBContext.db!!.execUpdate(sql!!)
}

/********************* delete ext. *********************/

fun String.db_delete(byAttr: String,
                     withVal: Any,
                     orderBy: String? = null,
                     ascending: Boolean = true,
                     limit: Int? = null,
                     offset: Int = 0): Boolean
{

    val condition = "$byAttr = ${sqlValClean(withVal)}"
    return this.db_delete(condition, orderBy, ascending, limit, offset)


}

fun String.db_delete(byAttr: String,
                     likePattern: String,
                     orderBy: String? = null,
                     ascending: Boolean = true,
                     limit: Int? = null,
                     offset: Int = 0): Boolean
{
    val condition = "$byAttr LIKE \"$likePattern\""
    return this.db_delete(condition, orderBy, ascending, limit, offset)
}

fun String.db_delete(where: String,
                     orderBy: String? = null,
                     ascending: Boolean = true,
                     limit: Int? = null,
                     offset: Int = 0): Boolean
{
    val sql = HPDBSQLBuilder()
            .deleteBuilder()
            .setTableName(this.tblName())
            .setCondition(where)
            .setOrderBy(orderBy)
            .setAscending(ascending)
            .setLimit(limit)
            .setOffset(offset)
            .build()

    assert(HPDBContext.db != null) {
        "db not found"
    }

    return HPDBContext.db!!.execUpdate(sql!!)
}

// async methods

fun String.db_delete(byAttr: String,
                     withVal: Any,
                     orderBy: String? = null,
                     ascending: Boolean = true,
                     limit: Int? = null,
                     offset: Int = 0,
                     callback: HPDBCallbackBlock)
{

    val condition = "$byAttr = ${sqlValClean(withVal)}"
    this.db_delete(condition, orderBy, ascending, limit, offset, callback)


}

fun String.db_delete(byAttr: String,
                     likePattern: String,
                     orderBy: String? = null,
                     ascending: Boolean = true,
                     limit: Int? = null,
                     offset: Int = 0,
                     callback: HPDBCallbackBlock)
{
    val condition = "$byAttr LIKE \"$likePattern\""
    this.db_delete(condition, orderBy, ascending, limit, offset, callback)
}

fun String.db_delete(where: String,
                     orderBy: String? = null,
                     ascending: Boolean = true,
                     limit: Int? = null,
                     offset: Int = 0,
                     callback: HPDBCallbackBlock)
{
    val sql = HPDBSQLBuilder()
            .deleteBuilder()
            .setTableName(this.tblName())
            .setCondition(where)
            .setOrderBy(orderBy)
            .setAscending(ascending)
            .setLimit(limit)
            .setOffset(offset)
            .build()

    assert(HPDBContext.db != null) {
        "db not found"
    }

    HPDBContext.db!!.execUpdate(sql!!, callback)
}

/********************* other ext. *********************/

fun String.db_schema(): ArrayList<JSONObject>? {
    val sql = HPDBSQLBuilder()
            .schemaSqlBuilder()
            .setTableName(this.tblName())
            .build()
    assert(HPDBContext.db != null) {
        "db not found"
    }

    return HPDBContext.db!!.execQuery(sql!!)
}

