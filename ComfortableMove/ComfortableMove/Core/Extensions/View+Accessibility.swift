//
//  View+Accessibility.swift
//  ComfortableMove
//
//  Created by 박성근 on 1/2/26.
//

import SwiftUI

// MARK: - View Extension for Accessibility

extension View {
    /// 한국어 VoiceOver 레이블 및 특성 추가
    /// - Parameters:
    ///   - label: VoiceOver가 읽어줄 핵심 텍스트
    ///   - hint: 동작에 대한 추가 설명 (예: "이 버튼을 누르면 ...합니다")
    ///   - value: 슬라이더나 토글 등의 현재 값 (예: "켜짐", "50%")
    ///   - traits: UI 요소의 특성 (예: .isButton, .isSelected, .isHeader)
    func accessibleLabel(_ label: String, hint: String? = nil, value: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self.modifier(AccessibilityModifier(label: label, hint: hint, value: value, traits: traits))
    }

    /// 여러 텍스트나 요소를 하나의 포커스로 묶어서 읽어줍니다.
    func accessibleGroup(combine: Bool = true, label: String? = nil, value: String? = nil, hint: String? = nil) -> some View {
        self.accessibilityElement(children: combine ? .combine : .ignore)
            .iflet(label) { $0.accessibilityLabel($1) }
            .iflet(value) { $0.accessibilityValue($1) }
            .iflet(hint) { $0.accessibilityHint($1) }
    }

    /// 장식용 이미지 표시 (VoiceOver에서 숨김)
    func decorativeImage() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Helper Extension
extension View {
    /// 조건부 Modifier 적용을 위한 헬퍼
    @ViewBuilder func iflet<T>(_ value: T?, transform: (Self, T) -> some View) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Accessibility Modifier

struct AccessibilityModifier: ViewModifier {
    let label: String
    let hint: String?
    let value: String?
    let traits: AccessibilityTraits

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .iflet(hint) { $0.accessibilityHint($1) }
            .iflet(value) { $0.accessibilityValue($1) }
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Common Accessibility Labels

struct A11yLabels {
    // MARK: - Navigation
    static let help = "도움말"
    static let helpHint = "앱 사용 방법을 확인합니다"

    static let settings = "설정"
    static let settingsHint = "알림음 설정과 앱 정보를 확인합니다"

    static let back = "뒤로 가기"

    static let refresh = "버스 도착 정보 새로고침"
    static let refreshHint = "가까운 정류장의 버스 도착 정보를 다시 불러옵니다"

    // MARK: - Main Actions
    static func notificationButton(selected: Bool, busName: String = "") -> String {
        if selected {
            return "배려석 알림 전송하기"
        } else {
            return "버스 선택 필요"
        }
    }

    static func notificationButtonHint(selected: Bool, busName: String = "") -> String {
        if selected {
            return "\(busName)번 버스의 배려석 알림을 전송합니다. 두 번 탭하여 실행하세요."
        } else {
            return "먼저 아래 목록에서 버스를 선택해주세요."
        }
    }
    
    static let notificationButtonValueSelected = "준비됨"
    static let notificationButtonValueUnselected = "비활성화됨"

    // MARK: - Bus Selection
    static func busSelection(routeName: String, busType: String, arrivalMsg: String?, congestion: String?, direction: String?, isSelected: Bool) -> String {
        var msg = ""

        // 버스 번호와 종류
        if !busType.isEmpty {
            msg += "\(routeName)번 \(busType) 버스, "
        } else {
            msg += "\(routeName)번 버스, "
        }

        // 방면
        if let dir = direction {
            msg += "\(dir) 방면, "
        }

        // 도착 정보
        if let arrival = arrivalMsg {
            msg += "\(arrival), "
        }

        // 혼잡도
        if let cong = congestion {
            msg += "혼잡도는 \(cong)입니다, "
        }

        // 선택 상태
        msg += isSelected ? "선택됨" : "선택 안 됨"

        return msg
    }

    static func busSelectionValue(isSelected: Bool) -> String {
        isSelected ? "선택됨" : "선택 안 됨"
    }

    static func busSelectionHint(isSelected: Bool) -> String {
        isSelected ? "두 번 탭하면 선택을 해제합니다" : "두 번 탭하여 이 버스를 선택합니다"
    }
    
    // MARK: - Station Info
    static func stationInfo(name: String, distance: String = "") -> String {
        "현재 정류장: \(name). \(distance)"
    }

    // MARK: - Onboarding
    static func onboardingPage(_ index: Int, total: Int) -> String {
        "\(index + 1)페이지 중 \(total)페이지"
    }

    static func pageIndicator(_ index: Int, isCurrent: Bool) -> String {
        "\(index + 1)페이지"
    }
    
    static func pageIndicatorValue(isCurrent: Bool) -> String {
        isCurrent ? "현재 페이지" : ""
    }

    static func onboardingImage(for index: Int) -> String {
        switch index {
        case 0:
            return "안녕하세요 맘편한 이동입니다. 임산부 분들의 편안하고 안전한 버스 배려석 탑승을 도와드립니다."
        case 1:
            return "탑승하려는 버스의 임산부 배려석에 알림을 줄 수 있습니다. 이로 인해 탑승객들의 자연스러운 배려석 양보가 가능합니다."
        case 2:
            return "쉽고 간편하게 이용하실 수 있습니다. GPS와 실시간 버스 데이터 기반으로 주변 정류장의 탑승할 버스 도착 정보를 확인하고, 알림만 울리면 끝입니다."
        case 3:
            return "임산부들만 이용가능합니다. 임산부 신고 후, 해당 서비스를 이용하실 수 있습니다. 임산부 신고는 e보건소 혹은 직접 방문, 아이마중 어플 등을 통해 가능합니다."
        case 4:
            return "맘편한 이동을 위한 필수 접근권한 안내입니다. 위치 권한은 현재 버스정류장 및 탑승할 버스를 안내하기 위해 필요합니다. 블루투스 권한은 버스 내부 배려석 알림 기기와 통신하기 위해 필요합니다."
        default:
            return "온보딩 이미지"
        }
    }

    // MARK: - Permission Icons
    static let locationIcon = "위치 권한"
    static let bluetoothIcon = "블루투스 권한"

    // MARK: - Splash
    static let appLogo = "맘편한 이동 로고"
    static let appLogoHint = "앱이 시작되는 중입니다"
    static let splashText = "예비 엄마의 마음 편한 이동"

    // MARK: - Info View
    static let appInfoImage = "임산부 캐릭터 일러스트"
    static let soundToggle = "배려석 알림음"
    static func soundToggleValue(_ enabled: Bool) -> String {
        enabled ? "켜짐" : "꺼짐"
    }
    static let soundToggleHint = "알림음을 켜거나 끕니다"

    static let appInquiry = "앱 문의"
    static let appInquiryHint = "구글 설문지로 이동하여 문의를 보냅니다. 외부 브라우저가 열립니다."

    static let privacyPolicy = "개인정보 처리 방침 및 이용약관"
    static let privacyPolicyHint = "노션 페이지로 이동하여 방침을 확인합니다. 외부 브라우저가 열립니다."
    
    // MARK: - Help
    static func helpPage(index: Int) -> String {
        "도움말 \(index + 1)페이지"
    }

    static func helpPageDescription(for index: Int) -> String {
        switch index {
        case 0:
            return """
도움말 첫 번째 페이지입니다. 버스 및 정류장 선택 방법을 안내합니다. 첫 단계는 버스 선택하기입니다. 화면 상단에는 이용 방법 안내가 있고, 하단에는 실제 버스를 선택할 수 있는 목록이 배치되어 있습니다. GPS를 기반으로 현재 위치에서 100미터 이내의 정류장과 버스 정보를 자동으로 불러옵니다. 원하는 버스를 확인한 후 오른쪽의 체크 버튼을 눌러 선택할 수 있습니다. 버스는 한 번에 한 대만 선택할 수 있습니다. 목록 상단에는 현재 인식된 정류장 이름과 방면이 표시됩니다. 정류장 이름 오른쪽의 새로고침 버튼을 누르면 현재 위치를 다시 검색하여 정류장 정보를 업데이트할 수 있습니다. 정류장 이름 아래에는 버스 번호, 도착 예정 시간, 현재 위치가 몇 번째 전인지, 그리고 종점 방향 정보가 표시됩니다. 버스 정보 오른쪽의 선택 버튼은 해당 버스를 타겠다고 확정하는 체크 버튼입니다.
"""
        case 1:
            return """
도움말 두 번째 페이지입니다. 알림 전송 방법을 안내합니다. 두 번째 단계는 알림 전송하기입니다. 화면 중앙에 가장 중요한 알림 전송 버튼이 크게 자리 잡고 있습니다. 버스를 선택한 후, 화면 중앙의 큰 벨 버튼을 누르면 버스 내 배려석에 양보 요청 알림이 즉시 전송됩니다. 알림이 전송되면 버스 좌석에는 소리, 불빛, 텍스트가 동시에 출력됩니다. 화면 한가운데에 위치한 큰 종 모양 버튼이 알림 전송 버튼이며, 이 버튼을 누르는 것이 최종 단계입니다. 알림 소리의 사용 여부는 앱 내 별도의 정보 메뉴에서 설정할 수 있습니다. 화면 하단에는 현재 선택한 버스 정보가 표시되어 있어, 어떤 버스에 알림을 보내는지 마지막으로 확인할 수 있습니다.
"""
        default:
            return "도움말 상세 이미지"
        }
    }
    
    static let helpImageHint = "두 손가락으로 왼쪽으로 스와이프하면 다음 도움말을 볼 수 있습니다"

    // MARK: - Announcements
    static func busSelectedAnnouncement(routeName: String, arrivalMsg: String?, congestion: String?, direction: String?) -> String {
        var msg = "\(routeName)번 버스가 선택되었습니다."
        if let arrival = arrivalMsg {
            msg += " 도착 정보: \(arrival)."
        }
        if let cong = congestion {
            msg += " 혼잡도: \(cong)."
        }
        if let dir = direction {
            msg += " \(dir) 방면."
        }
        msg += " 배려석 알림 전송 버튼이 활성화되었습니다."
        return msg
    }

    // MARK: - Bus Info Label (자연스러운 음성 안내)
    static func busInfoLabel(routeName: String, busType: String, arrivalMsg: String?, congestion: String?, direction: String?) -> String {
        var msg = ""

        // 버스 번호와 종류
        if !busType.isEmpty {
            msg += "\(routeName)번 \(busType) 버스, "
        } else {
            msg += "\(routeName)번 버스, "
        }

        // 방면
        if let dir = direction {
            msg += "\(dir) 방면, "
        }

        // 도착 정보
        if let arrival = arrivalMsg {
            msg += "\(arrival), "
        }

        // 혼잡도
        if let cong = congestion {
            msg += "혼잡도는 \(cong)입니다"
        } else {
            // 마지막 쉼표 제거
            msg = msg.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        }

        return msg
    }
}
