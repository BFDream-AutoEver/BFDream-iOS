//
//  LocationManager.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/30/25.
//

import Foundation
import CoreLocation

// MARK: - 위치 관리 클래스
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var showPermissionAlert = false

    var onLocationUpdate: ((CLLocation) -> Void)?
    private var hasInitialLocation = false

    override init() {
        super.init()
        manager.delegate = self
        // 버스 정류장 찾기에는 100m 정확도면 충분 (배터리 절약)
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLocation = location

        // 최초 위치 업데이트 시에만 콜백 호출 (중복 방지)
        if !hasInitialLocation {
            hasInitialLocation = true
            onLocationUpdate?(location)
        }

        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.log(message: "❌ 위치 업데이트 실패: \(error.localizedDescription)")
    }

    func refreshLocation() {
        hasInitialLocation = false // refresh 시에는 콜백 다시 허용
        manager.startUpdatingLocation()
    }
}
