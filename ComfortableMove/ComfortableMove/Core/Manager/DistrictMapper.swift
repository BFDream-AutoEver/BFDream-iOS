//
//  DistrictMapper.swift
//  ComfortableMove
//
//  Created by 박성근 on 11/14/25.
//

import Foundation

class DistrictMapper {
    static let shared = DistrictMapper()

    private var koreanToEnglish: [String: String] = [:]

    private init() {
        loadDistricts()
    }

    private func loadDistricts() {
        var path: String?

        // 디렉토리 지정, 없이, URL 방식으로 모두 찾는다.
        path = Bundle.main.path(forResource: "seoul_districts", ofType: "csv", inDirectory: "App/Resources/BusInfo")

        if path == nil {
            path = Bundle.main.path(forResource: "seoul_districts", ofType: "csv")
        }

        if path == nil {
            path = Bundle.main.url(forResource: "seoul_districts", withExtension: "csv")?.path
        }

        guard let finalPath = path else {
            Logger.log(message: "❌ seoul_districts.csv 파일을 찾을 수 없습니다")
            Logger.log(message: "Bundle path: \(Bundle.main.bundlePath)")
            return
        }

        do {
            let content = try String(contentsOfFile: finalPath, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)

            for line in lines {
                let columns = line.components(separatedBy: ",")
                if columns.count == 2 {
                    let korean = columns[0].trimmingCharacters(in: .whitespaces)
                    let english = columns[1].trimmingCharacters(in: .whitespaces)
                    if !korean.isEmpty && !english.isEmpty {
                        koreanToEnglish[korean] = english
                    }
                }
            }

            Logger.log(message: "✅ 서울 구 매핑 로드 완료: \(koreanToEnglish.count)개")
            Logger.log(message: "finalPath: \(finalPath)")
        } catch {
            Logger.log(message: "❌ seoul_districts.csv 로드 실패: \(error)")
        }
    }

    // MARK: 한글 버스 번호를 영어로 변환 (예: "강동01" → "Gangdong01", "2012" → "2012")
    func translateBusNumber(_ busNumber: String) -> String {
        // 버스 번호에서 한글 부분과 숫자/영문 부분 분리
        var koreanPart = ""
        var remainingPart = ""

        for char in busNumber {
            if char.unicodeScalars.first!.value >= 0xAC00 && char.unicodeScalars.first!.value <= 0xD7A3 {
                // 한글 범위 (가-힣)
                koreanPart.append(char)
            } else {
                // 숫자 또는 영문
                remainingPart.append(char)
            }
        }

        // 한글이 없으면 원본 그대로 반환 (예: "2012", "M5107")
        if koreanPart.isEmpty {
            Logger.log(message: "✅ 버스 번호 변환 불필요: \(busNumber)")
            return busNumber
        }

        // 한글 부분을 영어로 변환
        if let english = koreanToEnglish[koreanPart] {
            let translated = english + remainingPart
            Logger.log(message: "🔄 버스 번호 변환: \(busNumber) → \(translated)")
            return translated
        }

        // 매핑이 없으면 원본 반환
        Logger.log(message: "⚠️ 버스 번호 변환 실패 (매핑 없음): \(busNumber)")
        return busNumber
    }
}
