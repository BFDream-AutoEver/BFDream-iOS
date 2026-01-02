//
//  AlertManager.swift
//  ComfortableMove
//
//  Created by Claude on 11/15/25.
//

import Foundation
import SwiftUI

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
    case busDeviceNotFound // 추가

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
        }
    }

    var priority: Int {
        switch self {
        case .locationUnauthorized: return 3
        case .bluetoothUnsupported, .bluetoothUnauthorized: return 2
        case .bluetoothConfirm, .bluetoothSuccess, .bluetoothFailure, .busDeviceNotFound: return 1
        case .noBusInfo: return 1
        case .apiError: return 0
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
        }
    }

    var shouldBlockApp: Bool {
        switch self {
        case .bluetoothUnsupported, .bluetoothUnauthorized, .locationUnauthorized:
            return true
        case .noBusInfo, .apiError, .bluetoothConfirm, .bluetoothSuccess, .bluetoothFailure:
            return false
        case .busDeviceNotFound:
            return false
        }
    }

    var primaryButtonText: String {
        shouldBlockApp ? "설정으로 이동" : "확인"
    }

    var isConfirmAlert: Bool {
        if case .bluetoothConfirm = self {
            return true
        }
        return false
    }
}

// MARK: - Alert Manager
class AlertManager: ObservableObject {
    @Published var currentAlert: AlertType?

    func showAlert(_ type: AlertType) {
        // 현재 alert가 없거나, 새로운 alert의 우선순위가 더 높거나 같은 경우 표시
        if let current = currentAlert {
            if type.priority >= current.priority {
                currentAlert = type
            }
        } else {
            currentAlert = type
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
