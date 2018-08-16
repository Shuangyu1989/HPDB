package com.rkhd.breeze.hpdb

import android.content.Context
import net.sqlcipher.Cursor
import android.util.Log
import net.sqlcipher.database.SQLiteDatabase
import org.json.JSONObject

class HPEncryptDBHelper(context: Context,
                        dbName: String = HPDB_DEFAULT_NAME,
                        private val encryptionKey: String,
                        val version: Int = HPDB_INIT_VERSION) {

    private val dbFile = context.getDatabasePath(dbName)

    init {
        SQLiteDatabase.loadLibs(context)
    }

    fun execQuery(sql: String): ArrayList<JSONObject>? {
        var db: SQLiteDatabase? = try { SQLiteDatabase.openOrCreateDatabase(dbFile, encryptionKey, null) } catch(e: Exception) { null }
        var resultSet: ArrayList<JSONObject>? = null
        if (db != null && db.isOpen) {
            var cursor: Cursor? = null
            try {
                cursor = db.rawQuery(sql, null)
            } catch (e: Exception) {
                Log.d(HPDB_LOG_TAG, "SQL QUERY ERROR :${e.message}")
            } finally {
                if (cursor != null) {
                    if (cursor.moveToFirst()) {
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

                            if (resultSet == null) {
                                resultSet = arrayListOf()
                            }
                            resultSet.add(rowObject)
                            cursor.moveToNext()
                        }
                    }
                    cursor.close()
                }
            }

            db.close()
        } else {
            Log.d(HPDB_LOG_TAG, "SQL QUERY ERROR : DB cant be opened")
        }
        return resultSet
    }

    fun execUpdate(sql: String): Boolean {
        var db: SQLiteDatabase = SQLiteDatabase.openOrCreateDatabase(dbFile, encryptionKey, null)
        if (db.isOpen) {
            var flag = true
            try {
                db.rawExecSQL(sql)
            } catch (e: Exception){
                Log.d(HPDB_LOG_TAG, "SQL EXEC ERROR :${e.message}")
                flag = false
            } finally {
                db.close()
            }
            return flag
        } else {
            Log.d(HPDB_LOG_TAG, "SQL EXEC ERROR : DB cant be opened")
            return false
        }
    }

}