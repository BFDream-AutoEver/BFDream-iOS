//
//  BusArrivalService.swift
//  ComfortableMove
//
//  Created by Claude Code on 10/10/25.
//

import Foundation

class BusArrivalService {
    static let shared = BusArrivalService()

    private init() {}

    /// 정류소별 모든 버스 도착 정보 조회
    ///
    /// 백엔드 프록시(`/api/v1/bus/arrivals`)를 통해 호출. 응답 형식은
    /// 기존 서울 공공데이터 API 와 동일한 `BusArrivalResponse` 로 디코딩됨.
    /// (백엔드는 `app/services/seoul_bus_api.py` 에서 `normalize_arrival_response`
    ///  로 동일 키만 노출하도록 정규화함.)
    func getStationArrivalInfo(arsId: String) async throws -> [BusArrivalItem] {
        let url = try Self.buildURL(arsId: arsId)
        Logger.log(message: "🚌 [API] Request URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            Logger.log(message: "🚌 [API] Response Status: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(BusArrivalResponse.self, from: data)

        Logger.log(message: "🚌 [API] Header Code: \(result.msgHeader.headerCd)")
        Logger.log(message: "🚌 [API] Header Message: \(result.msgHeader.headerMsg)")
        Logger.log(message: "🚌 [API] Item Count: \(result.msgHeader.itemCount)")

        guard result.msgHeader.isSuccess else {
            Logger.log(message: "❌ [API] API Error: \(result.msgHeader.headerMsg)")
            throw NSError(
                domain: "APIError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: result.msgHeader.headerMsg]
            )
        }

        let items = result.msgBody.itemList ?? []
        Logger.log(message: "🚌 [API] Retrieved \(items.count) bus routes")

        for item in items {
            Logger.log(
                message: "🚌 [API] Route: \(item.rtNm), congestion1: \(item.congestion1 ?? "nil"), congestion: \(item.congestion.rawValue)"
            )
        }

        return items
    }

    // MARK: - URL Builder

    private static func buildURL(arsId: String) throws -> URL {
        if BackendConfig.useBackend {
            // 백엔드 프록시: /api/v1/bus/arrivals?ars_id=...
            let baseURL = "\(BackendConfig.baseURL)/api/v1/bus/arrivals"
            var components = URLComponents(string: baseURL)
            components?.queryItems = [
                URLQueryItem(name: "ars_id", value: arsId)
            ]
            guard let url = components?.url else {
                Logger.log(message: "❌ [API] Invalid backend URL")
                throw NSError(domain: "Invalid URL", code: -1)
            }
            return url
        }

        // 폴백: 서울 공공 API 직접 호출 (기존 경로)
        let baseURL = "http://ws.bus.go.kr/api/rest/stationinfo/getStationByUid"
        Logger.log(message: "🚌 [API] (legacy) API_KEY in use: \(API_KEY.isEmpty ? "EMPTY" : "set")")

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "ServiceKey", value: API_KEY),
            URLQueryItem(name: "arsId", value: arsId),
            URLQueryItem(name: "resultType", value: "json")
        ]
        guard let url = components?.url else {
            Logger.log(message: "❌ [API] Invalid URL")
            throw NSError(domain: "Invalid URL", code: -1)
        }
        return url
    }
}
