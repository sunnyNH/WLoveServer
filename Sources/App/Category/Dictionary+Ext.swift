//
//  Dic.swift
//  App
//
//  Created by 牛辉 on 2017/10/8.
//


import Foundation

extension Dictionary {
    mutating func merge<S:Sequence>(_ sequence: S) where S.Iterator.Element == (key:Key,value:Value) {
            sequence.forEach{ self[$0]=$1 }
    }
}

