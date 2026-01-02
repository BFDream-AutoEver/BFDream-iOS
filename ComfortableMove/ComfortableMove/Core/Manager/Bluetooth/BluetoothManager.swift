//
//  BluetoothManager.swift
//  ComfortableMove
//
//  Created by 박성근 on 10/18/25.
//

import Foundation
import CoreBluetooth

// 전송 결과 타입 정의
enum BluetoothTransferResult {
    case success
    case deviceNotFound
    case failure
}

class BluetoothManager: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var bluetoothState: CBManagerState = .unknown

    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var rxCharacteristic: CBCharacteristic?
    private var onTransmitComplete: ((BluetoothTransferResult) -> Void)?
    private var targetBusNumber: String?
    private var withSound: Bool = true

    var onBluetoothUnsupported: (() -> Void)?
    var onBluetoothUnauthorized: (() -> Void)?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func sendCourtesySeatNotification(busNumber: String, withSound: Bool, completion: @escaping (BluetoothTransferResult) -> Void) {
        self.onTransmitComplete = completion
        self.withSound = withSound

        // 한글 버스 번호를 영어로 변환 (예: "강동01" → "Gangdong01", "2012" → "2012")
        let translatedBusNumber = DistrictMapper.shared.translateBusNumber(busNumber)
        self.targetBusNumber = translatedBusNumber

        guard bluetoothState == .poweredOn else {
            Logger.log(message: "블루투스가 켜져있지 않습니다.")
            completion(.failure)
            return
        }

        guard let serviceUUID = BluetoothConfig.busServiceUUID else {
            Logger.log(message: "❌ Invalid Configuration: Bus Service UUID not found.")
            // 설정이 없으면 스캔 자체를 할 수 없으므로 deviceNotFound로 안내하거나 
            // 시스템 오류임을 알리기 위해 결과를 .deviceNotFound로 보냅니다.
            completion(.deviceNotFound) 
            return
        }

        Logger.log(message: "🔍 \(busNumber)번 버스 검색 시작... (ESP32: BF_DREAM_\(translatedBusNumber))")
        isScanning = true
        // Service UUID로 버스 기기만 스캔
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + BluetoothConfig.scanTimeout) { [weak self] in
            guard let self = self else { return }
            if self.isScanning {
                Logger.log(message: "⏰ 스캔 타임아웃 - \(busNumber)번 버스를 찾지 못했습니다.")
                self.stopScanning()
                self.onTransmitComplete?(.deviceNotFound)
            }
        }
    }

    private func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        Logger.log(message: "블루투스 스캔 중지")
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state

        switch central.state {
        case .poweredOff:
            Logger.log(message: "블루투스가 꺼져있습니다.")
            stopScanning()
        case .poweredOn:
            Logger.log(message: "블루투스가 켜져있습니다.")
        case .unauthorized:
            Logger.log(message: "블루투스 권한이 없습니다.")
            onBluetoothUnauthorized?()
        case .unsupported:
            Logger.log(message: "이 기기는 블루투스를 지원하지 않습니다.")
            onBluetoothUnsupported?()
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Advertisement Data에서 로컬 이름 확인
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let deviceName = localName

        Logger.log(message: "🚌 버스 기기 발견!")
        Logger.log(message: "  - peripheral.name: \(peripheral.name ?? "nil")")
        Logger.log(message: "  - localName: \(localName ?? "nil")")
        Logger.log(message: "  - 최종 deviceName: \(deviceName ?? "nil")")
        Logger.log(message: "  - RSSI: \(RSSI)")
        Logger.log(message: "  - 찾는 버스: \(targetBusNumber ?? "nil")번")

        guard let finalDeviceName = deviceName else {
            Logger.log(message: "⚠️ 디바이스 이름이 없는 기기 무시")
            return
        }

        // 버스 번호로 필터링 (대소문자 무시)
        guard let busNumber = BluetoothConfig.busNumber(from: finalDeviceName),
              busNumber.lowercased() == targetBusNumber?.lowercased() else {
            Logger.log(message: "⚠️ 다른 버스(\(BluetoothConfig.busNumber(from: finalDeviceName) ?? "알 수 없음")번) - 무시")
            return
        }

        // 목표 버스 발견!
        if targetPeripheral == nil {
            Logger.log(message: "✅ \(busNumber)번 버스 발견! 연결 시도...")
            targetPeripheral = peripheral
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
            stopScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Logger.log(message: "✅ \(targetBusNumber ?? "")번 버스 연결 성공")
        if let serviceUUID = BluetoothConfig.busServiceUUID {
            peripheral.discoverServices([serviceUUID])
        } else {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Logger.log(message: "❌ 연결 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
        stopScanning()
        onTransmitComplete?(.failure)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Logger.log(message: "🔌 연결 해제")
        targetPeripheral = nil
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            onTransmitComplete?(.failure)
            return
        }

        guard let serviceUUID = BluetoothConfig.busServiceUUID,
              let rxUUID = BluetoothConfig.rxCharacteristicUUID else {
            onTransmitComplete?(.failure)
            return
        }

        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([rxUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let characteristics = service.characteristics else {
            onTransmitComplete?(.failure)
            return
        }

        guard let rxUUID = BluetoothConfig.rxCharacteristicUUID else {
            onTransmitComplete?(.failure)
            return
        }

        for characteristic in characteristics {
            if characteristic.uuid == rxUUID {
                // 배려석 알림 데이터 전송
                let message = BluetoothConfig.courtesySeatMessage(withSound: self.withSound)
                if let data = message.data(using: .utf8) {
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                    Logger.log(message: "📤 \(targetBusNumber ?? "")번 버스에 배려석 알림 전송! (소리: \(self.withSound ? "ON" : "OFF"))")
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            Logger.log(message: "✅ 데이터 전송 성공!")
            onTransmitComplete?(.success)
        } else {
            Logger.log(message: "❌ 데이터 전송 실패: \(error?.localizedDescription ?? "")")
            onTransmitComplete?(.failure)
        }

        // 연결 해제
        centralManager.cancelPeripheralConnection(peripheral)
    }
}
