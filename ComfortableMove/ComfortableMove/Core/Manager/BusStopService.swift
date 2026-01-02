//
//  BusStopService.swift
//  ComfortableMove
//
//  Created by Claude Code on 11/5/25.
//

import Foundation
import CoreLocation

class BusStopService {
    static let shared = BusStopService()

    private init() {}

    // MARK: 위치 기반 주변 정류소 조회 -> 10m로 업데이트
    func getNearbyStations(location: CLLocation, radius: Int) async throws -> [StationItem] {
        let baseURL = "http://ws.bus.go.kr/api/rest/stationinfo/getStationByPos"

        Logger.log(message: "🚏 [API] Searching stations near (\(location.coordinate.latitude), \(location.coordinate.longitude))")

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "ServiceKey", value: API_KEY),
            URLQueryItem(name: "tmX", value: "\(location.coordinate.longitude)"),
            URLQueryItem(name: "tmY", value: "\(location.coordinate.latitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "resultType", value: "json")
        ]

        guard let url = components?.url else {
            Logger.log(message: "❌ [API] Invalid URL")
            throw NSError(domain: "Invalid URL", code: -1)
        }

        Logger.log(message: "🚏 [API] Request URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            Logger.log(message: "🚏 [API] Response Status: \(httpResponse.statusCode)")
        }

        // JSON 디코딩
        let decoder = JSONDecoder()
        let result = try decoder.decode(StationByPosResponse.self, from: data)

        Logger.log(message: "🚏 [API] Header Code: \(result.msgHeader.headerCd)")
        Logger.log(message: "🚏 [API] Header Message: \(result.msgHeader.headerMsg)")
        Logger.log(message: "🚏 [API] Item Count: \(result.msgHeader.itemCount)")

        // 서울 외 지역 체크
        if result.msgHeader.noBusInfo {
            Logger.log(message: "❌ [API] Out of Seoul: \(result.msgHeader.headerMsg)")
            throw NSError(domain: "noBusInfo", code: 4, userInfo: [NSLocalizedDescriptionKey: "버스 정보 없음"])
        }

        guard result.msgHeader.isSuccess else {
            Logger.log(message: "❌ [API] API Error: \(result.msgHeader.headerMsg)")
            throw NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: result.msgHeader.headerMsg])
        }

        let stations = result.msgBody.itemList ?? []
        Logger.log(message: "🚏 [API] Found \(stations.count) stations within \(radius)m")

        return stations
    }
}
