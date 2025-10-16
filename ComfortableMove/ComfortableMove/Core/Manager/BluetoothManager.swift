//
//  BluetoothManager.swift
//  ComfortableMove
//
//  Created by 박성근 on 10/16/25.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var bluetoothState: CBManagerState = .unknown

    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var onTransmitComplete: ((Bool) -> Void)?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // 배려석 알림 전송
    func sendCourtesySeatNotification(busNumber: String, completion: @escaping (Bool) -> Void) {
        self.onTransmitComplete = completion

        guard bluetoothState == .poweredOn else {
            print("블루투스가 켜져있지 않습니다.")
            completion(false)
            return
        }

        // 버스 블루투스 기기 스캔 시작
        isScanning = true
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])

        // 타임아웃 설정 (10초)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self else { return }
            if self.isScanning {
                self.stopScanning()
                self.onTransmitComplete?(false)
            }
        }
    }

    private func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        print("블루투스 스캔 중지")
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state

        switch central.state {
        case .poweredOff:
            print("블루투스가 꺼져있습니다.")
            stopScanning()
        case .poweredOn:
            print("블루투스가 켜져있습니다.")
        case .unauthorized:
            print("블루투스 권한이 없습니다.")
        case .unsupported:
            print("이 기기는 블루투스를 지원하지 않습니다.")
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("기기 발견: \(peripheral.name ?? "이름 없음") - \(peripheral.identifier)")

        // TODO: 버스 기기만 필터링하는 로직 추가 필요
        // - Service UUID로 버스 기기 식별
        // - 또는 기기 이름 패턴으로 필터링 (예: "BUS_", "MBeacon" 등)
        // - 현재는 모든 BLE 기기를 스캔하고 있음

        // TODO: 임시 코드 - 첫 번째 발견된 기기에 무조건 연결 시도
        // 실제로는 버스 기기인지 확인 후 연결해야 함
        if targetPeripheral == nil {
            targetPeripheral = peripheral
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("기기 연결 성공: \(peripheral.name ?? "이름 없음")")
        stopScanning()

        // TODO: 실제 배려석 알림 신호 전송 로직 구현 필요
        // 1. peripheral.delegate = self 설정
        // 2. peripheral.discoverServices()로 서비스 검색
        // 3. 적절한 Characteristic 찾기
        // 4. 배려석 알림 데이터 작성 (버스 번호, 좌석 정보 등)
        // 5. peripheral.writeValue()로 데이터 전송
        // 6. 전송 완료 확인 후 onTransmitComplete 호출

        // TODO: 임시 코드 - 연결만 성공해도 전송 성공으로 간주
        // 실제로는 데이터 전송이 완료된 후에 true를 반환해야 함
        onTransmitComplete?(true)

        // 연결 해제
        centralManager.cancelPeripheralConnection(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("기기 연결 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
        stopScanning()
        onTransmitComplete?(false)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("기기 연결 해제: \(peripheral.name ?? "이름 없음")")
        targetPeripheral = nil
    }
}
