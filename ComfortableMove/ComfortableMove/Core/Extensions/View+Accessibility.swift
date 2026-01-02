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
    static func busSelection(routeName: String, isSelected: Bool) -> String {
        "\(routeName)번 버스 선택"
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
        case 0: return "맘편한 이동 로고"
        case 1: return "배려석 양보를 돕는 알림 서비스 설명 그림"
        case 2: return "간편한 버스 알림 사용법 설명 그림"
        case 3: return "임산부 전용 서비스 안내 그림"
        case 4: return "필수 권한 안내"
        default: return "온보딩 이미지"
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
            return "1페이지 내용: 지피에스 기반 본인이 승차하려는 정류장과 버스번호를 확인 후, 체크표시를 눌러주세요. 버스 중복 선택은 불가능하며, 새로고침 버튼을 통해 정류장을 새로고침할 수도 있습니다."
        case 1:
            return "2페이지 내용: 중앙의 벨 모양 버튼을 클릭하여 배려석 알림을 울리면 끝입니다! 배려석 알림은 알림음, 불빛, 텍스트로 구성되어 있으나, 앱 정보 메뉴에서 알림음만 켜거나 끌 수 있습니다."
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
}
