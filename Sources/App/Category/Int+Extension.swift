//
//  Int+Extension.swift
//  NHServer
//
//  Created by niuhui on 2017/7/26.
//
//
import Foundation
import Vapor


extension Int {
    var is_toDay_Hour : Bool {
        let format = DateFormatter()
        format.dateFormat = "yyyyMMddHH"
        let now_at  = Int(Date().timeIntervalSince1970)
        if now_at - self < 60*60 {
            return true
        } else {
            return false
        }
    }
}
