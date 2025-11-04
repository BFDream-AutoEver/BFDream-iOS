//
//  StationByPosResponse.swift
//  ComfortableMove
//
//  Created by Claude Code on 11/5/25.
//

import Foundation

// MARK: - 위치 기반 정류소 조회 응답 모델 (JSON)
struct StationByPosResponse: Codable {
    let msgHeader: MsgHeader
    let msgBody: StationMsgBody
}

// MARK: - 정류소 메시지 본문
struct StationMsgBody: Codable {
    let itemList: [StationItem]?
}

// MARK: - 정류소 아이템
struct StationItem: Codable, Equatable {
    let stationId: String      // 정류소 고유 ID
    let stationNm: String      // 정류소명
    let arsId: String          // 정류소 번호 (API 호출용)
    let gpsX: String           // 정류소 좌표 X (WGS84)
    let gpsY: String           // 정류소 좌표 Y (WGS84)
    let dist: String           // 거리 (m)
    let stationTp: String      // 정류소 타입 (0:공용, 1:일반형, 7:마을버스 등)
}
