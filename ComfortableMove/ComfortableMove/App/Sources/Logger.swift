//
//  Logger.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/17/25.
//

import os

public enum Logger {
    public static func log(message: String) {
        os_log("\(message)")
    }
}
