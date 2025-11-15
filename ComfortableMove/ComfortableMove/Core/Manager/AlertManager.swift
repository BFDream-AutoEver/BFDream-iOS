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
    case outOfSeoul
    case apiError
    case bluetoothUnsupported
    case bluetoothUnauthorized
    case locationUnauthorized

    var id: String {
        switch self {
        case .outOfSeoul: return "outOfSeoul"
        case .apiError: return "apiError"
        case .bluetoothUnsupported: return "bluetoothUnsupported"
        case .bluetoothUnauthorized: return "bluetoothUnauthorized"
        case .locationUnauthorized: return "locationUnauthorized"
        }
    }

    var priority: Int {
        switch self {
        case .locationUnauthorized: return 3
        case .bluetoothUnsupported, .bluetoothUnauthorized: return 2
        case .outOfSeoul: return 1
        case .apiError: return 0
        }
    }

    var title: String {
        switch self {
        case .outOfSeoul:
            return "서울 외 지역"
        case .apiError:
            return "서버 오류"
        case .bluetoothUnsupported:
            return "블루투스 미지원"
        case .bluetoothUnauthorized:
            return "블루투스 권한 필요"
        case .locationUnauthorized:
            return "위치 권한 필요"
        }
    }

    var message: String {
        switch self {
        case .outOfSeoul:
            return "현재 서울 지역에서만 서비스를 이용할 수 있습니다."
        case .apiError:
            return "서버에 문제가 발생했습니다.\n잠시 후 다시 시도해주세요."
        case .bluetoothUnsupported:
            return "이 기기는 블루투스를 지원하지 않습니다.\n배려석 알림 기능을 사용할 수 없습니다."
        case .bluetoothUnauthorized:
            return "블루투스 권한이 필요합니다.\n설정에서 블루투스 권한을 허용해주세요."
        case .locationUnauthorized:
            return "위치 권한이 필요합니다.\n설정에서 위치 권한을 허용해주세요."
        }
    }

    var shouldBlockApp: Bool {
        switch self {
        case .bluetoothUnsupported, .bluetoothUnauthorized, .locationUnauthorized:
            return true
        case .outOfSeoul, .apiError:
            return false
        }
    }

    var primaryButtonText: String {
        shouldBlockApp ? "설정으로 이동" : "확인"
    }
}

// MARK: - Alert Manager
class AlertManager: ObservableObject {
    @Published var currentAlert: AlertType?

    func showAlert(_ type: AlertType) {
        // 현재 alert가 없거나, 새로운 alert의 우선순위가 더 높은 경우에만 표시
        if let current = currentAlert {
            if type.priority > current.priority {
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
