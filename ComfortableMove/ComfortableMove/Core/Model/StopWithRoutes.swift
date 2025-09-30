//
//  StopWithRoutes.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/30/25.
//

import Foundation

// MARK: - 정류장별 버스 노선 그룹
struct StopWithRoutes: Identifiable, Equatable {
    let id: Int
    let stopName: String
    let direction: String // 방향 정보
    let x: Double
    let y: Double
    let routes: [String] // 해당 정류장을 지나는 노선들
    
    init(stopName: String, x: Double, y: Double, routes: [String], id: Int) {
        self.id = id
        self.stopName = stopName
        self.direction = "건대입구역사거리 건대병원 방면" // 실제로는 데이터에서 가져와야 함
        self.x = x
        self.y = y
        self.routes = routes
    }
    
    static func == (lhs: StopWithRoutes, rhs: StopWithRoutes) -> Bool {
        return lhs.id == rhs.id &&
               lhs.stopName == rhs.stopName &&
               lhs.routes == rhs.routes
    }
}
