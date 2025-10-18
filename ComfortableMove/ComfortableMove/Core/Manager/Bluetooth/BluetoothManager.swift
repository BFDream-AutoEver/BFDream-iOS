//
//  BluetoothManager.swift
//  ComfortableMove
//
//  Created by 박성근 on 10/18/25.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var bluetoothState: CBManagerState = .unknown

    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var rxCharacteristic: CBCharacteristic?
    private var onTransmitComplete: ((Bool) -> Void)?
    private var targetBusNumber: String?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func sendCourtesySeatNotification(busNumber: String, completion: @escaping (Bool) -> Void) {
        self.onTransmitComplete = completion
        self.targetBusNumber = busNumber

        guard bluetoothState == .poweredOn else {
            Logger.log(message: "블루투스가 켜져있지 않습니다.")
            completion(false)
            return
        }

        Logger.log(message: "🔍 \(busNumber)번 버스 검색 시작...")
        isScanning = true
        // Service UUID로 버스 기기만 스캔
        centralManager.scanForPeripherals(
            withServices: [BluetoothConfig.busServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + BluetoothConfig.scanTimeout) { [weak self] in
            guard let self = self else { return }
            if self.isScanning {
                Logger.log(message: "⏰ 스캔 타임아웃 - \(busNumber)번 버스를 찾지 못했습니다.")
                self.stopScanning()
                self.onTransmitComplete?(false)
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
        case .unsupported:
            Logger.log(message: "이 기기는 블루투스를 지원하지 않습니다.")
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Advertisement Data에서 로컬 이름 확인
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let deviceName = peripheral.name ?? localName

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

        // 버스 번호로 필터링
        guard let busNumber = BluetoothConfig.busNumber(from: finalDeviceName),
              busNumber == targetBusNumber else {
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
        peripheral.discoverServices([BluetoothConfig.busServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Logger.log(message: "❌ 연결 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
        stopScanning()
        onTransmitComplete?(false)
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
            onTransmitComplete?(false)
            return
        }

        for service in services {
            if service.uuid == BluetoothConfig.busServiceUUID {
                peripheral.discoverCharacteristics([BluetoothConfig.rxCharacteristicUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let characteristics = service.characteristics else {
            onTransmitComplete?(false)
            return
        }

        for characteristic in characteristics {
            if characteristic.uuid == BluetoothConfig.rxCharacteristicUUID {
                // 배려석 알림 데이터 전송
                if let data = BluetoothConfig.courtesySeatMessage.data(using: .utf8) {
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                    Logger.log(message: "📤 \(targetBusNumber ?? "")번 버스에 배려석 알림 전송!")
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            Logger.log(message: "✅ 데이터 전송 성공!")
            onTransmitComplete?(true)
        } else {
            Logger.log(message: "❌ 데이터 전송 실패: \(error?.localizedDescription ?? "")")
            onTransmitComplete?(false)
        }

        // 연결 해제
        centralManager.cancelPeripheralConnection(peripheral)
    }
}
