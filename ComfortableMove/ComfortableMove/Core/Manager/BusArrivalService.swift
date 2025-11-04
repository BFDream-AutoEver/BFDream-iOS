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
    func getStationArrivalInfo(arsId: String) async throws -> [BusArrivalItem] {
        let baseURL = "http://ws.bus.go.kr/api/rest/stationinfo/getStationByUid"

        Logger.log(message: "🚌 [API] API_KEY: \(API_KEY)")

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

        Logger.log(message: "🚌 [API] Request URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            Logger.log(message: "🚌 [API] Response Status: \(httpResponse.statusCode)")
        }

        // JSON 디코딩
        let decoder = JSONDecoder()
        let result = try decoder.decode(BusArrivalResponse.self, from: data)

        Logger.log(message: "🚌 [API] Header Code: \(result.msgHeader.headerCd)")
        Logger.log(message: "🚌 [API] Header Message: \(result.msgHeader.headerMsg)")
        Logger.log(message: "🚌 [API] Item Count: \(result.msgHeader.itemCount)")

        guard result.msgHeader.isSuccess else {
            Logger.log(message: "❌ [API] API Error: \(result.msgHeader.headerMsg)")
            return []
        }

        let items = result.msgBody.itemList ?? []
        Logger.log(message: "🚌 [API] Retrieved \(items.count) bus routes")

        return items
    }
}
