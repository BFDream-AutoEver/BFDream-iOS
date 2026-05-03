//
//  DeviceIdentityManager.swift
//  ComfortableMove
//
//  Created by Claude Code on 5/4/26.
//

import Foundation

/// 익명 사용자 식별을 위한 UUID 기반 디바이스 ID 관리.
/// 백엔드 `boarding/record`, `statistics/*` API 의 `device_id` 와 동일 형식.
/// 앱 최초 실행 시 1회 생성하고 UserDefaults 에 영구 보관.
enum DeviceIdentityManager {
    private static let storageKey = "deviceIdentityUUID"

    static var deviceId: UUID {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let uuid = UUID(uuidString: raw) {
            return uuid
        }
        let new = UUID()
        UserDefaults.standard.set(new.uuidString, forKey: storageKey)
        Logger.log(message: "🆔 [Device] 신규 device_id 생성: \(new.uuidString)")
        return new
    }
}
