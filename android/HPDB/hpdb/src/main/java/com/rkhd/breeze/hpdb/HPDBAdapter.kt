package com.rkhd.breeze.hpdb

import android.content.Context
import android.os.AsyncTask
import org.json.JSONObject

typealias HPDBCallbackBlock = (Any?) -> Unit

class HPDBAdapter(context: Context,
                  dbName: String = HPDB_DEFAULT_NAME,
                  encryptionKey: String? = null,
                  version: Int = HPDB_INIT_VERSION) {

    class HPDBAsyncTask(private val dbHelper: Any,
                        private val actionType: String,
                        private val sql: String,
                        private val callback: HPDBCallbackBlock): AsyncTask<String, Int, Any?>() {

        override
        fun doInBackground(vararg p0: String?): Any? {
            return when(dbHelper) {
                is HPDBHelper -> {
                    if (actionType.toUpperCase() == "QUERY") {
                        dbHelper.execQuery(sql)
                    } else {
                        dbHelper.execUpdate(sql)
                    }
                }
                is HPEncryptDBHelper -> {
                    if (actionType.toUpperCase() == "QUERY") {
                        dbHelper.execQuery(sql)
                    } else {
                        dbHelper.execUpdate(sql)
                    }
                }
                else -> null
            }
        }

        override
        fun onPostExecute(result: Any?) {
            callback(result)
        }
    }

    var plainDBHelper: HPDBHelper? = null
    var encryptedDBHelper: HPEncryptDBHelper? = null
    var schemaCache = hashMapOf<String, ArrayList<HPDBColumnDesc>>()


    init {
        if (encryptionKey != null) {
            encryptedDBHelper = HPEncryptDBHelper(context, dbName, encryptionKey, version)
        } else {
            plainDBHelper = HPDBHelper(context, dbName, version)
        }
    }

    fun schemaOf(table: String): ArrayList<HPDBColumnDesc>? {
        val cache = schemaCache[table]
        if (cache != null) {
            return cache
        }

        val schemaInfo = table.db_schema()

        if (schemaInfo == null || schemaInfo.size == 0) {
            return null
        }
        
        val ret = arrayListOf<HPDBColumnDesc>()
        schemaInfo.map {
            ret.add(HPDBColumnDesc(it.getString("name"), sqliteTypeOf(it.getString("type"))))
        }
        schemaCache[table] = ret
        return ret
    }

    fun execUpdate(sql: String): Boolean {
        return when(encryptedDBHelper != null) {
            true -> encryptedDBHelper!!.execUpdate(sql)
            false -> plainDBHelper!!.execUpdate(sql)
        }
    }

    fun execQuery(sql: String): ArrayList<JSONObject>? {
        return when (encryptedDBHelper != null) {
            true -> encryptedDBHelper!!.execQuery(sql)
            false -> plainDBHelper!!.execQuery(sql)
        }
    }

    fun execUpdate(sql: String, callback: HPDBCallbackBlock) {
        when (encryptedDBHelper != null) {
            true -> {
                HPDBAsyncTask(encryptedDBHelper!!, "UPDATE", sql, callback).execute()
            }
            false -> {
                HPDBAsyncTask(plainDBHelper!!, "UPDATE", sql, callback).execute()
            }
        }
    }
    fun execQuery(sql: String, callback: HPDBCallbackBlock) {
        when (encryptedDBHelper != null) {
            true -> {
                HPDBAsyncTask(encryptedDBHelper!!, "QUERY", sql, callback).execute()
            }
            false -> {
                HPDBAsyncTask(plainDBHelper!!, "QUERY", sql, callback).execute()
            }
        }
    }
}