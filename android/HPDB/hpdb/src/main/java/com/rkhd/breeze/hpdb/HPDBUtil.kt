package com.rkhd.breeze.hpdb
import org.json.JSONArray
import org.json.JSONObject
import java.util.*


const val HPDB_INIT_VERSION = 1
const val HPDB_DEFAULT_NAME = "brz_app.sqlite"
const val HPDB_LOG_TAG = "[HPDB]"

fun <T> JSONArray.toArrayList(): ArrayList<T> {
    val result = arrayListOf<T>()
    for (i in 0 until this.length()) {
        result.add(this.get(i) as T)
    }
    return result
}

fun ClosedRange<Int>.random() = Random().nextInt((endInclusive + 1) - start) +  start

fun Boolean.int() = if (this) 1 else 0
fun Int.bool() = this == 1

/****************************** String ext ******************************/

fun String.removeFirst(): String {
    return this.substring(1)
}

fun String.removeLast(): String {
    return this.substring(0, this.length - 1)
}

/****************************** Date ext ******************************/

fun Date.timeIntervalSince1970(): Long {
    val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
    cal.time = this
    return cal.timeInMillis
}

/****************************** JSONObject ext ******************************/

fun JSONObject.nullable_getInt(name: String): Int? {
    return try { this.getInt(name) } catch(e: Exception) { null }
}

fun JSONObject.nullable_getIntWithDefaultVal(name: String,
                                             defaultVal: Int = 0): Int {
    return try { this.getInt(name) } catch(e: Exception) { defaultVal }
}

fun JSONObject.nullable_getString(name: String): String? {
    return try { this.getString(name) } catch(e: Exception) { null }
}

fun JSONObject.nullable_getBoolean(name: String): Boolean? {
    return try { this.getBoolean(name) } catch(e: Exception) { null }
}

fun JSONObject.nullable_getBooleanWithDefaultVal(name: String,
                                                 defaultVal: Boolean = false): Boolean {
    return try { this.getBoolean(name) } catch(e: Exception) { defaultVal }
}

//fun JSONObject.nullable_getBooleanMaybeFromInt(name: String): Boolean? {
//    return try { this.getBoolean(name) } catch(e: Exception) { null }
//}

fun JSONObject.nullable_getDouble(name: String): Double? {
    return try { this.getDouble(name) } catch(e: Exception) { null }
}

fun JSONObject.nullable_getDoubleWithDefaultVal(name: String,
                                                defaultVal: Double = 0.0): Double {
    return try { this.getDouble(name) } catch(e: Exception) { defaultVal }
}

fun JSONObject.nullable_getLong(name: String): Any? {
    return try { this.getLong(name) } catch(e: Exception) { null }
}

fun JSONObject.nullable_get(name: String): Any? {
    return try { this.get(name) } catch(e: Exception) { null }
}

fun JSONObject.nullable_getJSONObject(name: String): JSONObject? {
    return try { this.getJSONObject(name) } catch(e: Exception) { null }
}

fun JSONObject.nullable_getJSONArray(name: String): JSONArray? {
    return try { this.getJSONArray(name) } catch(e: Exception) { null }
}
