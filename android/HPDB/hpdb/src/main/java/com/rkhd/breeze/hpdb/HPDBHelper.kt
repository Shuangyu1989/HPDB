package com.rkhd.breeze.hpdb

import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteException
import android.util.Log
import org.json.JSONObject

class HPDBHelper(context: Context,
                 dbName: String = HPDB_DEFAULT_NAME,
                 version: Int = HPDB_INIT_VERSION)
    : SQLiteOpenHelper(context, dbName, null, version) {

    init {
        Log.v(HPDB_LOG_TAG, "db path: ${readableDatabase.path}")
    }

    override fun onCreate(db: SQLiteDatabase) {
    }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
    }
    override fun onDowngrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
    }

    fun execQuery(sql: String): ArrayList<JSONObject>? {
        val db = readableDatabase
        var cursor: Cursor?
        val resultSet = ArrayList<JSONObject>()
        try {
            cursor = db.rawQuery(sql, null)
            if (cursor!!.moveToFirst()) {
                while (!cursor.isAfterLast) {
                    val totalColumn = cursor.columnCount
                    val rowObject = JSONObject()
                    for (i in 0 until totalColumn) {
                        if (cursor.getColumnName(i) != null) {
                            when (cursor.getType(i)) {
                                Cursor.FIELD_TYPE_FLOAT -> rowObject.put(cursor.getColumnName(i), cursor.getFloat(i))
                                Cursor.FIELD_TYPE_INTEGER -> rowObject.put(cursor.getColumnName(i), cursor.getInt(i))
                                Cursor.FIELD_TYPE_STRING -> rowObject.put(cursor.getColumnName(i), cursor.getString(i))
                                Cursor.FIELD_TYPE_BLOB -> rowObject.put(cursor.getColumnName(i), cursor.getBlob(i))
                            }
                        }
                    }
                    resultSet.add(rowObject)
                    cursor.moveToNext()
                }
                cursor.close()
            }
        } catch (e: SQLiteException){
            Log.d(HPDB_LOG_TAG, "SQL EXEC ERROR ${e.message}")
            return null
        }

        if (resultSet.isEmpty()) return null else return resultSet
    }

    fun execUpdate(sql: String): Boolean {
        val db = writableDatabase
        try {
            db.execSQL(sql)
            return true
        } catch (e: SQLiteException){
            Log.d(HPDB_LOG_TAG, "SQL EXEC ERROR ${e.message}")
            return false
        }
    }
}

