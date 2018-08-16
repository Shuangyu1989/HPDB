package com.rkhd.breeze.hpdb

import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.util.*
import kotlin.collections.ArrayList


enum class HPDBColumnType(val rawVal: String) {
    INTEGER("integer"),
    TEXT("text"),
    REAL("real"),
    NONE("none")
}

fun sqliteTypeOf(rawType: String): HPDBColumnType {
    return when (rawType.toLowerCase()) {
        "long", "integer", "short", "boolean", "date" -> HPDBColumnType.INTEGER
        "string", "text", "object" -> HPDBColumnType.TEXT
        "float", "double", "real" -> HPDBColumnType.REAL
        else -> HPDBColumnType.NONE
    }
}

data class HPDBColumnDesc(val name: String,
                          val type: HPDBColumnType,
                          val primaryKey: Boolean = false,
                          val autoIncrement: Boolean = false,
                          val nullable: Boolean = true,
                          val defaultVal: Any? = null) {

    fun toSql(): String {
        var sql = "${this.name} ${this.type.rawVal}"

        if (this.primaryKey) {
            sql += " PRIMARY KEY"
        }

        if (this.autoIncrement) {
            sql += " AUTOINCREMENT"
        }

        if (!this.nullable) {
            sql += " NOT NULL"
        }

        if (this.defaultVal != null) {
            sql += " DEFAULT ${this.defaultVal}"
        }
        return sql
    }
}


fun sqlHeal(rawSQL: String): String {
    return rawSQL
            .replace( "<null>", "null")
}
fun stringValClean(str: String): String {
    var result = str
    result = result.replace("\"", "\"\"").db_sqlValClean()
    return result
}
fun sqlValClean(rawVal: Any?): Any {
    var ret: Any
    if (rawVal == null) {
        ret = "null"
    } else if (rawVal is String) {
        ret = "\"${stringValClean(rawVal)}\""
    } else if (rawVal is JSONObject || rawVal is Map<*, *>) {
        ret = "\"${stringValClean(rawVal.toString())}\""
    } else if (rawVal is List<*> || rawVal is JSONArray) {
        ret = "\"${stringValClean(rawVal.toString())}\""
    } else if (rawVal is Date) {
        ret = rawVal.timeIntervalSince1970()
    } else if (rawVal is Boolean) {
        ret = rawVal.int()
    } else {
        ret = rawVal
    }
    return ret
}

class HPDBSQLBuilder {
    enum class SQLType {
        NONE,
        CREATE_TABLE,
        BATCH_INSERT,
        INSERT,
        DELETE,
        UPDATE,
        QUERY,
        SCHEMA,
        ADD_COLUMN,
        INDEX,
        DELETE_TABLE
    }

    private fun sqlBuildError(msg: String): String {
        return "[DB_SQL_Builder_Error] $msg"
    }

    private var mTableName: String? = null
    private var mSQLType = SQLType.NONE
    private var mColumnDesc: ArrayList<HPDBColumnDesc>? = null
    private var mJSONObjArr: ArrayList<JSONObject>? = null
    private var mJSONObj: JSONObject? = null
    private var mCondition: String? = null
    private var mOrderBy: String? = null
    private var mAscending: Boolean = true
    private var mLimit: Int? = null
    private var mOffset: Int = 0
    private var mQueryColumns: ArrayList<String>? = null
    private var mIndexColumns: ArrayList<String>? = null

    fun setSQLType(type: SQLType): HPDBSQLBuilder {
        this.mSQLType = type
        return this
    }

    fun setTableName(tblName: String): HPDBSQLBuilder {
        this.mTableName = tblName.tblName()
        return this
    }

    fun setCondition(con: String?): HPDBSQLBuilder {
        this.mCondition = con
        return this
    }

    fun setOrderBy(clm: String?): HPDBSQLBuilder {
        this.mOrderBy = clm
        return this
    }

    fun setAscending(asec: Boolean): HPDBSQLBuilder {
        this.mAscending = asec
        return this
    }

    fun setLimit(limit: Int?): HPDBSQLBuilder {
        this.mLimit = limit
        return this
    }

    fun setOffset(offset: Int): HPDBSQLBuilder {
        this.mOffset = offset
        return this
    }

    fun setColumnDesc(clmDesc: ArrayList<HPDBColumnDesc>?): HPDBSQLBuilder {
        this.mColumnDesc = clmDesc
        return this
    }

    fun setRecords(rs: ArrayList<JSONObject>?): HPDBSQLBuilder {
        this.mJSONObjArr = rs
        return this
    }

    fun setRecord(r: JSONObject?): HPDBSQLBuilder {
        this.mJSONObj = r
        return this
    }

    fun setQueryColumns(clms: ArrayList<String>?): HPDBSQLBuilder {
        this.mQueryColumns = clms
        return this
    }

    fun setIndexColumns(clms: ArrayList<String>?): HPDBSQLBuilder {
        this.mIndexColumns = clms
        return this
    }

    /********************* table create sql builder *********************/

    fun tableCreateBuilder(): HPDBSQLBuilder {
        this.mSQLType = SQLType.CREATE_TABLE
        return this
    }

    /********************* insert sql builder *********************/

    fun batchInsertBuilder(): HPDBSQLBuilder {
        this.mSQLType = SQLType.BATCH_INSERT
        return this
    }

    fun insertBuilder(): HPDBSQLBuilder {
        this.mSQLType = SQLType.INSERT
        return this
    }

    /********************* delete sql builder *********************/

    fun deleteBuilder(): HPDBSQLBuilder {
        this.mSQLType = SQLType.DELETE
        return this
    }

    /********************* update sql builder *********************/

    fun updateBuilder(): HPDBSQLBuilder {
        this.mSQLType = SQLType.UPDATE
        return this
    }

    /********************* query sql builder *********************/

    fun queryBuilder(): HPDBSQLBuilder {
        this.mSQLType = SQLType.QUERY
        return this
    }

    /********************* schema sql builder *********************/

    fun schemaSqlBuilder(): HPDBSQLBuilder {
        this.mSQLType = SQLType.SCHEMA
        return this
    }

    /********************* add column sql builder *********************/

    fun addColumnSqlBuilder(): HPDBSQLBuilder {
        this.mSQLType = SQLType.ADD_COLUMN
        return this
    }

    /********************* index sql builder *********************/

    fun indexSqlBuilder(): HPDBSQLBuilder {
        this.mSQLType = SQLType.INDEX
        return this
    }

    private fun insertSqlOf(record: JSONObject): String {
        var clms = ""
        var vals = ""
        val keys = record.keys()
        keys.forEach {
            clms = "$clms,$it"
            vals = "$vals,${sqlValClean(record.get(it))}"
        }
        clms = clms.substring(1)
        vals = vals.substring(1)

        return "INSERT INTO $mTableName ($clms) VALUES ($vals)"
    }

    fun build(): String? {
        assert(mTableName != null) { sqlBuildError("table name can't be empty") }
        var sql: String?
        when (mSQLType) {
            SQLType.CREATE_TABLE -> {
                assert(mColumnDesc != null) { sqlBuildError("column desc can't be empty") }
                val clmDesc = mColumnDesc!!
                        .map { it.toSql() }
                        .reduce { ret, e -> "$ret,$e" }

                sql = "CREATE TABLE IF NOT EXISTS $mTableName ($clmDesc)"
            }
            SQLType.BATCH_INSERT -> {
                assert(mJSONObjArr != null && mJSONObjArr!!.isNotEmpty()) { sqlBuildError("records can't be empty") }
                sql = mJSONObjArr!!.map {
                    insertSqlOf(it)
                }.reduce { ret, e -> "$ret; $e" }
            }
            SQLType.INSERT -> {
                assert(mJSONObj != null) { sqlBuildError("record can't be empty") }
                sql = insertSqlOf(mJSONObj!!)
                sql = sqlHeal(sql)
            }
            SQLType.DELETE -> {
                assert(mCondition != null) { sqlBuildError("condition can't be empty") }
                sql = "DELETE FROM $mTableName WHERE $mCondition"
                if (mOrderBy != null) {
                    sql += " ORDER BY $mOrderBy"
                }
                if (mLimit != null ){
                    sql += " LIMIT $mLimit OFFSET $mOffset"
                }
            }
            SQLType.UPDATE -> {
                assert(mJSONObj != null) { sqlBuildError("record can't be empty") }
                assert(mCondition != null) { sqlBuildError("condition can't be empty") }
                var record = ""

                mJSONObj!!.keys().forEach {
                    record = "$record, $it=${sqlValClean(mJSONObj!!.get(it))}"
                }
                record = record.substring(1)
                sql =  "UPDATE $mTableName SET $record WHERE $mCondition"
                sql = sqlHeal(sql)
            }
            SQLType.QUERY -> {
                var fields = "*"
                if (mQueryColumns != null) {
                    fields = mQueryColumns!!.joinToString(",")
                }

                sql = "SELECT $fields FROM $mTableName"

                if (mCondition != null) {
                    sql += " WHERE $mCondition"
                }

                if (mOrderBy != null) {
                    var ascending = "ASC"
                    if (!mAscending) {
                        ascending = "DESC"
                    }
                    sql += " ORDER BY $mOrderBy $ascending"
                }
                if (mLimit != null) {
                    sql += " LIMIT $mLimit OFFSET $mOffset"
                }
            }
            SQLType.SCHEMA -> {
                sql = "PRAGMA TABLE_INFO($mTableName)"
            }
            SQLType.ADD_COLUMN -> {

                val clmDesc = mColumnDesc!!
                        .mapNotNull { it.toSql() }
                        .joinToString(";")
                sql = "ALTER TABLE $mTableName ADD COLUMN $clmDesc"
            }
            SQLType.INDEX -> {
                sql = mIndexColumns!!
                        .mapNotNull { "CREATE INDEX ${it}_idx ON $mTableName ($it)" }
                        .joinToString(";")
            }
            SQLType.DELETE_TABLE -> {
                sql = "DROP TABLE IF EXISTS $mTableName"
            }
            else -> {
                sql = ""
            }
        }
        val ret = sqlHeal(sql)
        Log.v("HPDB SQL", ret)
        return ret
    }
}