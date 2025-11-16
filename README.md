# 맘편한 이동 (ComfortableMove)

임신부를 위한 서울시 버스 교통약자석 알림 iOS 앱

---

## 📌 프로젝트 소개

맘편한 이동은 임신부가 서울시 버스에서 교통약자석을 편리하게 요청할 수 있도록 돕는 iOS 애플리케이션입니다. GPS 기반 위치 서비스로 주변 버스 정류장을 찾고, 실시간 버스 도착 정보를 확인한 후, 블루투스를 통해 버스 내 교통약자석 알림 장치로 알림을 전송합니다.

---

## 🎯 주요 기능

- **위치 기반 정류장 검색**: GPS로 현재 위치 기준 500m 내 버스 정류장 자동 검색
- **실시간 버스 도착 정보**: 서울시 버스 API를 통한 실시간 버스 도착 정보 제공
- **블루투스 교통약자석 알림**: ESP32 기반 버스 내 장치로 교통약자석 요청 메시지 전송
- **다국어 지원**: 한국어 기본 설정
- **온보딩 가이드**: 앱 사용법 및 권한 설명 제공

---

## 🔧 기술 스택

- **UI**: SwiftUI
- **위치 서비스**: CoreLocation
- **블루투스**: CoreBluetooth (BLE)
- **비동기 처리**: Async/await, Combine
- **API**: 서울시 버스 Open API
- **아키텍처**: MVC 기반 구조

---

## 📁 프로젝트 구조

```
ComfortableMove/
├── App/
│   ├── Sources/              # 앱 진입점, 설정 파일
│   └── Resources/            # 이미지, 폰트, CSV 데이터
└── Core/
    ├── Extensions/           # 확장 기능들
    ├── Manager/              # 위치, API, 블루투스 관리
    ├── Model/                # 데이터 모델
    └── Presentation/         # 화면 (Splash, Home, Help)
```

---

## 🌐 API 정보

**서울시 버스 Open API**
- `getStationByPos`: GPS 좌표 기반 정류장 검색
- `getStationByUid`: 실시간 버스 도착 정보
- 서울시 지역만 서비스 제공

---

## 📡 블루투스 장치 규격

- **프로토콜**: BLE (Bluetooth Low Energy)
- **장치 이름 형식**: `BF_DREAM_[버스번호]`
- **ESP32 기반** 교통약자석 알림 장치

---

## 📄 라이선스

MIT License
