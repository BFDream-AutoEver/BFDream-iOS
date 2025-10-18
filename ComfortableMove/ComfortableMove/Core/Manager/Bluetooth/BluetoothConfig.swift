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
    
    static let busServiceUUID: CBUUID = {
        guard let uuidString = infoDictionary?["BUS_SERVICE_UUID"] as? String else {
            fatalError("BUS_SERVICE_UUID not found in Info.plist")
        }
        return CBUUID(string: uuidString)
    }()
    
    static let rxCharacteristicUUID: CBUUID = {
        guard let uuidString = infoDictionary?["RX_CHARACTERISTIC_UUID"] as? String else {
            fatalError("RX_CHARACTERISTIC_UUID not found in Info.plist")
        }
        return CBUUID(string: uuidString)
    }()
    
    static let txCharacteristicUUID: CBUUID = {
        guard let uuidString = infoDictionary?["TX_CHARACTERISTIC_UUID"] as? String else {
            fatalError("TX_CHARACTERISTIC_UUID not found in Info.plist")
        }
        return CBUUID(string: uuidString)
    }()
    
    static let deviceNamePrefix: String = {
        guard let prefix = infoDictionary?["DEVICE_NAME_PREFIX"] as? String else {
            fatalError("DEVICE_NAME_PREFIX not found in Info.plist")
        }
        return prefix
    }()
    
    static let courtesySeatMessage: String = {
        guard let message = infoDictionary?["COURTESY_SEAT_MESSAGE"] as? String else {
            fatalError("COURTESY_SEAT_MESSAGE not found in Info.plist")
        }
        return message
    }()
    
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
