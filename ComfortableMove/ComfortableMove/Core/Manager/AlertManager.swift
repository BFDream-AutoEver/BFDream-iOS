//
//  AlertManager.swift
//  ComfortableMove
//
//  Created by Claude on 11/15/25.
//

import Foundation
import SwiftUI
import Network

// MARK: - Alert Types
enum AlertType: Identifiable {
    case noBusInfo
    case apiError
    case bluetoothUnsupported
    case bluetoothUnauthorized
    case locationUnauthorized
    case bluetoothConfirm(busName: String, onConfirm: () -> Void, onCancel: () -> Void)
    case bluetoothSuccess
    case bluetoothFailure
    case busDeviceNotFound
    case externalLink(title: String, url: URL, onConfirm: () -> Void)
    case networkUnavailable

    var id: String {
        switch self {
        case .noBusInfo: return "noBusInfo"
        case .apiError: return "apiError"
        case .bluetoothUnsupported: return "bluetoothUnsupported"
        case .bluetoothUnauthorized: return "bluetoothUnauthorized"
        case .locationUnauthorized: return "locationUnauthorized"
        case .bluetoothConfirm: return "bluetoothConfirm"
        case .bluetoothSuccess: return "bluetoothSuccess"
        case .bluetoothFailure: return "bluetoothFailure"
        case .busDeviceNotFound: return "busDeviceNotFound"
        case .externalLink: return "externalLink"
        case .networkUnavailable: return "networkUnavailable"
        }
    }

    var priority: Int {
        switch self {
        case .networkUnavailable: return 4 // 가장 높은 우선순위
        case .locationUnauthorized: return 3
        case .bluetoothUnsupported, .bluetoothUnauthorized: return 2
        case .bluetoothConfirm, .bluetoothSuccess, .bluetoothFailure, .busDeviceNotFound: return 1
        case .noBusInfo: return 1
        case .apiError: return 0
        case .externalLink: return 1
        }
    }

    var title: String {
        switch self {
        case .noBusInfo:
            return "버스 정보 없음"
        case .apiError:
            return "서버 오류"
        case .bluetoothUnsupported:
            return "블루투스 미지원"
        case .bluetoothUnauthorized:
            return "블루투스 권한 필요"
        case .locationUnauthorized:
            return "위치 권한 필요"
        case .bluetoothConfirm(let busName, _, _):
            return "\(busName)버스에 배려석 알림을 전송하시겠습니까?"
        case .bluetoothSuccess:
            return "알림 전송 완료"
        case .bluetoothFailure:
            return "버스 배려석 알림 전송에 실패하였습니다."
        case .busDeviceNotFound:
            return "알림 기기를 찾을 수 없음"
        case .externalLink:
            return "외부 링크 이동"
        case .networkUnavailable:
            return "네트워크 연결 필요"
        }
    }

    var message: String {
        switch self {
        case .noBusInfo:
            return "버스 정류장 주변 서비스 가능한 버스가 없습니다."
        case .apiError:
            return "서버에 문제가 발생했습니다.\n잠시 후 다시 시도해주세요."
        case .bluetoothUnsupported:
            return "이 기기는 블루투스를 지원하지 않습니다.\n배려석 알림 기능을 사용할 수 없습니다."
        case .bluetoothUnauthorized:
            return "블루투스 권한이 필요합니다.\n'설정 > 맘편한 이동'에서 블루투스 권한을 허용해주세요."
        case .locationUnauthorized:
            return "위치 권한이 필요합니다.\n'설정 > 맘편한 이동 > 위치'에서 '앱을 사용하는 동안'으로 설정해주세요."
        case .bluetoothConfirm:
            return ""
        case .bluetoothSuccess:
            return ""
        case .bluetoothFailure:
            return "다시 한번 시도해주세요."
        case .busDeviceNotFound:
            return "해당 버스에 알림 기기가 설치되지 않았거나,\n현재 신호가 약하여 연결할 수 없습니다."
        case .externalLink(let pageName, _, _):
            return "'\(pageName)' 페이지로 이동하시겠습니까?\n앱을 벗어나 브라우저가 실행됩니다."
        case .networkUnavailable:
            return "인터넷에 연결되어 있지 않습니다.\nWi-Fi 또는 셀룰러 데이터를 켜주세요."
        }
    }

    var shouldBlockApp: Bool {
        switch self {
        case .bluetoothUnsupported, .bluetoothUnauthorized, .locationUnauthorized, .networkUnavailable:
            return true
        case .noBusInfo, .apiError, .bluetoothConfirm, .bluetoothSuccess, .bluetoothFailure:
            return false
        case .busDeviceNotFound:
            return false
        case .externalLink:
            return false
        }
    }

    var primaryButtonText: String {
        shouldBlockApp ? "설정으로 이동" : "확인"
    }

    var isConfirmAlert: Bool {
        switch self {
        case .bluetoothConfirm, .externalLink:
            return true
        default:
            return false
        }
    }
}

// MARK: - Alert Manager
class AlertManager: ObservableObject {
    @Published var currentAlert: AlertType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var isNetworkConnected: Bool = true // 현재 네트워크 상태 저장

    init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let isConnected = path.status == .satisfied
                self?.isNetworkConnected = isConnected
                
                if isConnected {
                    // 네트워크가 연결되면 네트워크 관련 알림만 닫음
                    if case .networkUnavailable = self?.currentAlert {
                        self?.currentAlert = nil
                    }
                } else {
                    // 네트워크 끊김 -> 알림 표시
                    self?.showAlert(.networkUnavailable)
                }
            }
        }
        monitor.start(queue: queue)
    }

    func showAlert(_ type: AlertType) {
        var typeToDisplay = type
        
        // 네트워크가 끊겨있는데 API 관련 에러가 들어오면, 네트워크 에러 알림으로 교체
        if !isNetworkConnected {
            switch type {
            case .apiError, .noBusInfo:
                typeToDisplay = .networkUnavailable
            default:
                break
            }
        }
        
        // 현재 alert가 없거나, 새로운 alert의 우선순위가 더 높거나 같은 경우 표시
        if let current = currentAlert {
            if typeToDisplay.priority >= current.priority {
                currentAlert = typeToDisplay
            }
        } else {
            currentAlert = typeToDisplay
        }
    }

    func dismissAlert() {
        currentAlert = nil
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
