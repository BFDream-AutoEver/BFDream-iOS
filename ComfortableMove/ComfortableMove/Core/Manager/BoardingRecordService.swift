//
//  BoardingRecordService.swift
//  ComfortableMove
//
//  Created by Claude Code on 5/4/26.
//

import Foundation

/// 배려석 알림 전송 결과를 백엔드(`POST /api/v1/boarding/record`) 로 기록.
/// 백엔드 `app/schemas/boarding.py:BoardingRecordRequest` 와 1:1 매핑.
/// 백엔드 통계(`/api/v1/statistics/*`) 의 데이터 소스.
class BoardingRecordService {
    static let shared = BoardingRecordService()

    private init() {}

    /// 백엔드 `notification_status` Literal 과 정확히 동일.
    /// (backend: `Literal["success", "device_not_found", "failure"]`)
    enum NotificationStatus: String {
        case success
        case deviceNotFound = "device_not_found"
        case failure

        static func from(_ result: BluetoothTransferResult) -> NotificationStatus {
            switch result {
            case .success: return .success
            case .deviceNotFound: return .deviceNotFound
            case .failure: return .failure
            }
        }
    }

    /// 백엔드 BoardingRecordRequest 와 동일한 키/타입 (snake_case 유지).
    private struct Payload: Encodable {
        let device_id: String?
        let route_name: String
        let route_type: String?
        let bus_device_id: String?
        let station_id: String?
        let station_name: String?
        let ars_id: String?
        let latitude: Double?
        let longitude: Double?
        let sound_enabled: Bool
        let notification_status: String
    }

    /// 배려석 알림 전송 결과 기록 — fire-and-forget.
    /// 네트워크 실패는 UX 를 차단하지 않고 로그만 남김.
    func record(
        routeName: String,
        routeType: String?,
        busDeviceId: String?,
        station: StationItem?,
        latitude: Double?,
        longitude: Double?,
        soundEnabled: Bool,
        status: NotificationStatus
    ) async {
        guard BackendConfig.useBackend else {
            Logger.log(message: "📝 [Boarding] useBackend=false — skip record")
            return
        }

        guard let url = URL(string: "\(BackendConfig.baseURL)/api/v1/boarding/record") else {
            Logger.log(message: "❌ [Boarding] Invalid backend URL")
            return
        }

        let payload = Payload(
            device_id: DeviceIdentityManager.deviceId.uuidString,
            route_name: routeName,
            route_type: routeType,
            bus_device_id: busDeviceId,
            station_id: station?.stationId,
            station_name: station?.stationNm,
            ars_id: station?.arsId,
            latitude: latitude,
            longitude: longitude,
            sound_enabled: soundEnabled,
            notification_status: status.rawValue
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            Logger.log(message: "❌ [Boarding] Encode failed: \(error)")
            return
        }

        Logger.log(message: "📤 [Boarding] POST \(url.absoluteString) — route=\(routeName), status=\(status.rawValue)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if (200..<300).contains(http.statusCode) {
                    Logger.log(message: "✅ [Boarding] HTTP \(http.statusCode)")
                } else {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    Logger.log(message: "❌ [Boarding] HTTP \(http.statusCode): \(body)")
                }
            }
        } catch {
            Logger.log(message: "❌ [Boarding] Network error: \(error.localizedDescription)")
        }
    }
}
