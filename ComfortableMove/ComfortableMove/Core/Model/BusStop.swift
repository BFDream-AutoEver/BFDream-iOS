//
//  BusStop.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/30/25.
//

import Foundation

// MARK: - 버스 정류장 모델
struct BusStop: Identifiable, Codable {
    let id: Int // NODE_ID
    let routeId: Int
    let routeName: String // 노선명
    let arsId: Int
    let stopName: String // 정류소명
    let x: Double // X좌표
    let y: Double // Y좌표
    
    enum CodingKeys: String, CodingKey {
        case routeId = "ROUTE_ID"
        case routeName = "노선명"
        case id = "NODE_ID"
        case arsId = "ARS_ID"
        case stopName = "정류소명"
        case x = "X좌표"
        case y = "Y좌표"
    }
    
    // 두 좌표 사이의 거리 계산 (유클리드 거리)
    func distance(to coordinate: (x: Double, y: Double)) -> Double {
        let dx = x - coordinate.x
        let dy = y - coordinate.y
        return sqrt(dx * dx + dy * dy)
    }
}
