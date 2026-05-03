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

    // MARK: 위치 기반 주변 정류소 조회 (백엔드 프록시)
    ///
    /// 백엔드 프록시(`/api/v1/bus/stations`)를 통해 호출. 파라미터(`tmX, tmY, radius`)
    /// 와 응답 모델(`StationByPosResponse`)은 기존 서울 API 와 동일.
    func getNearbyStations(location: CLLocation, radius: Int) async throws -> [StationItem] {
        let url = try Self.buildURL(
            longitude: location.coordinate.longitude,
            latitude: location.coordinate.latitude,
            radius: radius
        )

        Logger.log(message: "🚏 [API] Searching stations near (\(location.coordinate.latitude), \(location.coordinate.longitude))")
        Logger.log(message: "🚏 [API] Request URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            Logger.log(message: "🚏 [API] Response Status: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(StationByPosResponse.self, from: data)

        Logger.log(message: "🚏 [API] Header Code: \(result.msgHeader.headerCd)")
        Logger.log(message: "🚏 [API] Header Message: \(result.msgHeader.headerMsg)")
        Logger.log(message: "🚏 [API] Item Count: \(result.msgHeader.itemCount)")

        // 서울 외 지역
        if result.msgHeader.noBusInfo {
            Logger.log(message: "❌ [API] Out of Seoul: \(result.msgHeader.headerMsg)")
            throw NSError(
                domain: "noBusInfo",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "버스 정보 없음"]
            )
        }

        guard result.msgHeader.isSuccess else {
            Logger.log(message: "❌ [API] API Error: \(result.msgHeader.headerMsg)")
            throw NSError(
                domain: "APIError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: result.msgHeader.headerMsg]
            )
        }

        let stations = result.msgBody.itemList ?? []
        Logger.log(message: "🚏 [API] Found \(stations.count) stations within \(radius)m")

        return stations
    }

    // MARK: - URL Builder

    private static func buildURL(longitude: Double, latitude: Double, radius: Int) throws -> URL {
        if BackendConfig.useBackend {
            // 백엔드 프록시: /api/v1/bus/stations?tmX=lon&tmY=lat&radius=N
            let baseURL = "\(BackendConfig.baseURL)/api/v1/bus/stations"
            var components = URLComponents(string: baseURL)
            components?.queryItems = [
                URLQueryItem(name: "tmX", value: "\(longitude)"),
                URLQueryItem(name: "tmY", value: "\(latitude)"),
                URLQueryItem(name: "radius", value: "\(radius)")
            ]
            guard let url = components?.url else {
                Logger.log(message: "❌ [API] Invalid backend URL")
                throw NSError(domain: "Invalid URL", code: -1)
            }
            return url
        }

        // 폴백: 서울 공공 API 직접 호출 (기존 경로)
        let baseURL = "http://ws.bus.go.kr/api/rest/stationinfo/getStationByPos"
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "ServiceKey", value: API_KEY),
            URLQueryItem(name: "tmX", value: "\(longitude)"),
            URLQueryItem(name: "tmY", value: "\(latitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "resultType", value: "json")
        ]
        guard let url = components?.url else {
            Logger.log(message: "❌ [API] Invalid URL")
            throw NSError(domain: "Invalid URL", code: -1)
        }
        return url
    }
}
