package com.rkhd.breeze.hpdb

object HPDBContext {

    private var mDB: HPDBAdapter? = null
    var db: HPDBAdapter?
    get() {
        return mDB
    }
    set(newVal) {
        mDB = newVal
    }


}