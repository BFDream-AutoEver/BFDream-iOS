//
//  BusArrivalResponse.swift
//  ComfortableMove
//
//  Created by Claude Code on 10/10/25.
//

import Foundation
import SwiftUI

// MARK: - 버스 노선 유형
enum BusRouteType {
    case gangseon      // 간선 (파란색, 3자리)
    case jiseon        // 지선 (초록색, 4자리)
    case sunhwan       // 순환 (노란색, 2자리)
    case gwangyeok     // 광역 (빨간색, 9로 시작하는 4자리)
    case maeul         // 마을 (초록색)
    case simya         // 심야 (N으로 시작)
    case gongHang      // 공항 (회색)
    case unknown

    var color: Color {
        switch self {
        case .gangseon, .simya:
            return Color("TrunkBus_NBus")
        case .jiseon, .maeul:
            return Color("FeederBus_TownBus")
        case .sunhwan:
            return Color("CircularBus")
        case .gwangyeok:
            return Color("WideAreaBus")
        case .gongHang:
            return Color.gray
        case .unknown:
            return Color.gray
        }
    }

    var displayName: String {
        switch self {
        case .gangseon: return "간선"
        case .jiseon: return "지선"
        case .sunhwan: return "순환"
        case .gwangyeok: return "광역"
        case .maeul: return "마을"
        case .simya: return "심야"
        case .gongHang: return "공항"
        case .unknown: return ""
        }
    }

    // 버스 번호로부터 노선 유형 판별
    static func from(busNumber: String) -> BusRouteType {
        let trimmed = busNumber.trimmingCharacters(in: .whitespaces)

        // 심야버스: N으로 시작
        if trimmed.uppercased().hasPrefix("N") {
            return .simya
        }

        // 숫자만 추출
        let digits = trimmed.filter { $0.isNumber }
        let length = digits.count

        guard length > 0 else { return .unknown }

        // 광역버스: 9로 시작하는 4자리
        if length == 4 && digits.first == "9" {
            return .gwangyeok
        }

        // 간선버스: 3자리
        if length == 3 {
            return .gangseon
        }

        // 지선버스: 4자리 (9로 시작하지 않음)
        if length == 4 {
            return .jiseon
        }

        // 순환버스: 2자리
        if length == 2 {
            return .sunhwan
        }

        // 마을버스: 자치구명 포함되어 있거나 특수한 경우
        if trimmed.contains(where: { !$0.isNumber && $0 != "N" && $0 != "n" }) {
            return .maeul
        }

        return .unknown
    }
}

// MARK: - 버스 도착 정보 응답 모델 (JSON)
struct BusArrivalResponse: Codable {
    let msgHeader: MsgHeader
    let msgBody: MsgBody
}

// MARK: - 메시지 헤더
struct MsgHeader: Codable {
    let headerCd: String
    let headerMsg: String
    let itemCount: Int

    var isSuccess: Bool {
        return headerCd == "0"
    }

    var noBusInfo: Bool {
        return headerCd == "4" && headerMsg == "결과가 없습니다."
    }
}

// MARK: - 메시지 본문
struct MsgBody: Codable {
    let itemList: [BusArrivalItem]?
}

// MARK: - 버스 도착 정보 아이템
struct BusArrivalItem: Codable {
    let rtNm: String           // 노선명 (예: "721")
    let arrmsg1: String?       // 첫번째 버스 도착 메시지 (예: "2분후[2번째 전]")
    let adirection: String?    // 방향 (예: "신설동")
    let routeType: String      // 노선유형 (3:간선, 4:지선 등)
    let isFullFlag1: String?   // 만차 여부 (0:만차아님, 1:만차)
    let isLast1: String?       // 막차 여부 (0:막차아님, 1:막차)

    // 버스 번호로부터 계산된 노선 유형
    var busType: BusRouteType {
        return BusRouteType.from(busNumber: rtNm)
    }
}
