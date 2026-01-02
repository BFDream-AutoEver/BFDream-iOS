//
//  BluetoothConfig.swift
//  ComfortableMove
//
//  Created by 박성근 on 10/18/25.
//

import Foundation
import CoreBluetooth

struct BluetoothConfig {
    private static let infoDictionary = Bundle.main.infoDictionary
    
    static var busServiceUUID: CBUUID? {
        guard let uuidString = infoDictionary?["BUS_SERVICE_UUID"] as? String, !uuidString.isEmpty else {
            Logger.log(message: "❌ [Config] BUS_SERVICE_UUID missing or empty")
            return nil
        }
        // 유효하지 않은 UUID 문자열일 경우 CBUUID(string:)에서 크래시가 날 수 있으므로 예외처리 필요하지만,
        // CBUUID 생성자는 실패 시 Obj-C 예외를 던지므로 Swift에서 잡기 어렵습니다.
        // 따라서 Info.plist에 정확한 값이 있다고 가정하되, 최소한의 빈 문자열 체크는 수행합니다.
        return CBUUID(string: uuidString)
    }
    
    static var rxCharacteristicUUID: CBUUID? {
        guard let uuidString = infoDictionary?["RX_CHARACTERISTIC_UUID"] as? String, !uuidString.isEmpty else {
            Logger.log(message: "❌ [Config] RX_CHARACTERISTIC_UUID missing or empty")
            return nil
        }
        return CBUUID(string: uuidString)
    }
    
    static var txCharacteristicUUID: CBUUID? {
        guard let uuidString = infoDictionary?["TX_CHARACTERISTIC_UUID"] as? String, !uuidString.isEmpty else {
            Logger.log(message: "❌ [Config] TX_CHARACTERISTIC_UUID missing or empty")
            return nil
        }
        return CBUUID(string: uuidString)
    }
    
    static var deviceNamePrefix: String {
        guard let prefix = infoDictionary?["DEVICE_NAME_PREFIX"] as? String else {
            return "BF_DREAM_" // 기본값 제공
        }
        return prefix
    }
    
    static func courtesySeatMessage(withSound: Bool) -> String {
        return withSound ? "DEFAULT" : "SILENT"
    }
    
    static let scanTimeout: TimeInterval = 10
    
    static func busNumber(from deviceName: String) -> String? {
        guard deviceName.hasPrefix(deviceNamePrefix) else {
            return nil
        }
        
        let startIndex = deviceName.index(deviceName.startIndex, offsetBy: deviceNamePrefix.count)
        return String(deviceName[startIndex...])
    }
    
    static func deviceName(for busNumber: String) -> String {
        return deviceNamePrefix + busNumber
    }
}
