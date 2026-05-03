//
//  AppConfig.swift
//  ComfortableMove
//
//  Created by 박성근 on 10/10/25.
//

import Foundation

// 서울 공공데이터 API 키 — 백엔드 프록시 전환 후에는 클라이언트에서 사용하지 않음.
// (히스토리/롤백을 위해 일시적으로 유지)
let API_KEY = Bundle.main.infoDictionary?["API_KEY"] as? String ?? ""

/// 백엔드(ComfortableMove API) 호출 설정
enum BackendConfig {

    /// 백엔드 베이스 URL — Info.plist 의 BACKEND_BASE_URL 에서 로드.
    /// xcconfig 에서 dev/prod 별로 분기 가능.
    static let baseURL: String = {
        let raw = Bundle.main.infoDictionary?["BACKEND_BASE_URL"] as? String
        let trimmed = raw?.trimmingCharacters(in: .whitespaces) ?? ""
        return trimmed.isEmpty ? "http://localhost:8000" : trimmed
    }()

    /// 백엔드 사용 여부 — false 인 경우 기존 서울 API 직접 호출 경로로 폴백.
    /// 일단 기본값 true (백엔드 프록시 사용).
    static let useBackend: Bool = true
}
