//
//  HPDBContext.swift
//  DBTest
//
//  Created by rkhd on 2018/7/4.
//  Copyright © 2018 rkhd. All rights reserved.
//

import Foundation

public class HPDBContext {
  public static let `default` = HPDBContext()
  private var _db: HPDB? = nil
  public var db: HPDB? {
    get {
      return _db
    }
    set(newVal) {
      _db = newVal
    }
  }
  private static let _db_version_key = "app_db_version_key"
  public var version: Int {
    get {
      return UserDefaults.standard.integer(forKey: HPDBContext._db_version_key)
    }
    set (newVersion) {
      UserDefaults.standard.set(newVersion, forKey: HPDBContext._db_version_key)
    }
  }
}
