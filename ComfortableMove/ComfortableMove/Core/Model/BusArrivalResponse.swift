//
//  BusArrivalResponse.swift
//  ComfortableMove
//
//  Created by Claude Code on 10/10/25.
//

import Foundation

// MARK: - 버스 도착 정보 응답 모델
struct BusArrivalResponse: Codable {
    let serviceResult: ServiceResult

    enum CodingKeys: String, CodingKey {
        case serviceResult = "ServiceResult"
    }
}

// MARK: - 서비스 결과
struct ServiceResult: Codable {
    let msgHeader: MsgHeader
    let msgBody: MsgBody?

    enum CodingKeys: String, CodingKey {
        case msgHeader
        case msgBody
    }
}

// MARK: - 메시지 헤더
struct MsgHeader: Codable {
    let headerCd: String
    let headerMsg: String

    var isSuccess: Bool {
        return headerCd == "0"
    }
}

// MARK: - 메시지 본문
struct MsgBody: Codable {
    let itemList: [BusArrivalItem]?
}

// MARK: - 버스 도착 정보 아이템
struct BusArrivalItem: Codable {
    let arrmsg1: String?  // 첫번째 도착예정 메시지 (예: "10분1초후[6번째 전]")
}
