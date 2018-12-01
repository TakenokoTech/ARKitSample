//
//  ARLog.swift
//  ARKitSample
//
//  Created by たけのこ on 2018/12/02.
//  Copyright © 2018 たけのこ. All rights reserved.
//

import Foundation

class ARLog {
    
    public static func debug(_ obj: Any?, function: String = #function, line: Int = #line) {
        #if DEBUG
        print("\(nowDate()) [Function:\(function) Line:\(line)] : \(obj ?? "")")
        #endif
    }
    
    public static func funcIn(_ obj: Any? = nil, function: String = #function, line: Int = #line) {
        print("\(nowDate()) [Function:\(function) Line:\(line)] >> \(obj ?? "")")
    }
    
    public static func funcOut(_ obj: Any? = nil, function: String = #function, line: Int = #line) {
        print("\(nowDate()) [Function:\(function) Line:\(line)] << \(obj ?? "")")
    }
    
    private static func nowDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "jp")
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let date = dateFormatter.string(from: Date())
        return date
    }
}
