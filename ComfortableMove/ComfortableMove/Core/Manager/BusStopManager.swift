//
//  BusStopManager.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/30/25.
//

import Foundation
import CoreLocation

class BusStopManager: ObservableObject {
    @Published var nearestStop: StopWithRoutes?
    @Published var isLoading = false

    private var allBusStops: [BusStop] = []
    private var groupedStops: [String: (stop: BusStop, routes: [String])] = [:]

    init() {
        loadBusStops()
    }
    
    // MARK: - CSV 데이터 로딩
    private func loadBusStops() {
        // App/Resources/BusStop/ 경로에서 파일 찾기
        guard let path = Bundle.main.path(forResource: "Resources/BusStop/bus_route_stops", ofType: "csv") else {
            // 대안 경로 시도
            guard let alternativePath = Bundle.main.path(forResource: "bus_route_stops", ofType: "csv") else {
                Logger.log(message: "❌ CSV 파일을 찾을 수 없습니다 - 경로: Resources/BusStop/bus_route_stops.csv")
                return
            }
            Logger.log(message: "✅ 대안 경로에서 CSV 파일 발견")
            loadCSVFromPath(alternativePath)
            return
        }
        
        loadCSVFromPath(path)
    }
    
    private func loadCSVFromPath(_ path: String) {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines)
            
            // 헤더 제외하고 파싱
            for row in rows.dropFirst() where !row.isEmpty {
                let columns = parseCSVRow(row)
                
                guard columns.count >= 7,
                      let routeId = Int(columns[0]),
                      let nodeId = Int(columns[2]),
                      let arsId = Int(columns[3]),
                      let x = Double(columns[5]),
                      let y = Double(columns[6]) else {
                    continue
                }
                
                let busStop = BusStop(
                    id: nodeId,
                    routeId: routeId,
                    routeName: columns[1],
                    arsId: arsId,
                    stopName: columns[4],
                    x: x,
                    y: y
                )
                
                allBusStops.append(busStop)
            }

            Logger.log(message: "✅ \(allBusStops.count)개의 정류장 데이터 로드 완료")
            groupBusStops()
        } catch {
            Logger.log(message: "❌ CSV 로드 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 정류장 그룹화 (초기화 시 한 번만 실행)
    private func groupBusStops() {
        for busStop in allBusStops {
            let key = "\(busStop.stopName)_\(busStop.x)_\(busStop.y)"

            if var existing = groupedStops[key] {
                existing.routes.append(busStop.routeName)
                groupedStops[key] = existing
            } else {
                groupedStops[key] = (stop: busStop, routes: [busStop.routeName])
            }
        }
        Logger.log(message: "✅ \(groupedStops.count)개의 고유 정류장으로 그룹화 완료")
    }
    
    // CSV 행 파싱 (쉼표로 구분, 따옴표 처리)
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        result.append(currentField.trimmingCharacters(in: .whitespaces))
        return result
    }
    
    // MARK: - 가장 가까운 정류장 찾기
    func findNearestStop(userLocation: CLLocation) {
        isLoading = true

        // 백그라운드에서 계산
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let userCoord = (x: userLocation.coordinate.longitude,
                           y: userLocation.coordinate.latitude)

            // 가장 가까운 정류장 찾기 (이미 그룹화된 데이터 사용)
            var nearestDistance = Double.infinity
            var nearest: (stop: BusStop, routes: [String])?

            for (_, group) in self.groupedStops {
                let distance = group.stop.distance(to: userCoord)
                if distance < nearestDistance {
                    nearestDistance = distance
                    nearest = group
                }
            }

            // 메인 스레드에서 UI 업데이트
            DispatchQueue.main.async {
                if let nearest = nearest {
                    self.nearestStop = StopWithRoutes(
                        stopName: nearest.stop.stopName,
                        x: nearest.stop.x,
                        y: nearest.stop.y,
                        routes: nearest.routes.sorted(),
                        id: nearest.stop.id
                    )
                    Logger.log(message: "📍 가장 가까운 정류장: \(nearest.stop.stopName) (거리: \(String(format: "%.0f", nearestDistance))m)")
                    Logger.log(message: "🚌 지나는 버스: \(nearest.routes.joined(separator: ", "))")
                }
                self.isLoading = false
            }
        }
    }
}
