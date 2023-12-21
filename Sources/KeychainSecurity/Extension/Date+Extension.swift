//
//  File.swift
//  
//
//  Created by Book on 2023/12/21.
//

import Foundation

extension Date {
    public static var now: Date {
        Date(timeIntervalSince1970: Date().timeIntervalSince1970)
    }
}
