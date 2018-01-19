//
//  String(md5).swift
//  NHServer
//
//  Created by niuhui on 2017/5/10.
//
//

import Crypto
import Vapor
import Validation

extension String {
    
    var md5 : String {
        do {
            let byes   = self.makeBytes()
            let result = try Hash.make(.md5, byes)
            return result.hexString
        } catch {
            return ""
        }
    }
    
    var isPhone: Bool {
        do {
            try Count.equals(11).validate(self)
            try OnlyAlphanumeric.init().validate(self)
            let range = self.range(of: "^(1[0-9])\\d{9}$", options: .regularExpression)
            guard let _ = range else {
                return false
            }
            return true
        } catch {
            return false
        }
    }
    var isPassWord: Bool {
        do {
            try Count.min(6).validate(self)
            try Count.max(20).validate(self)
            try OnlyAlphanumeric.init().validate(self)
            return true
        } catch {
            return false
        }
    }
}
