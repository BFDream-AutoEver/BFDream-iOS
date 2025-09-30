//
//  LocationManagerTests.swift
//  ComfortableMoveTest
//
//  Created by 박성근 on 9/30/25.
//

import XCTest
import CoreLocation
@testable import ComfortableMove

final class LocationManagerTests: XCTestCase {
    var sut: LocationManager!

    override func setUp() {
        super.setUp()
        sut = LocationManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 초기화 테스트
    func 초기_상태에서_currentLocation은_nil이고_showPermissionAlert는_false이다() {
        // Given & When: LocationManager 초기화 (setUp에서 수행됨)

        // Then: 초기 상태 확인
        XCTAssertNil(sut.currentLocation, "초기 상태에서 currentLocation은 nil이어야 함")
        XCTAssertFalse(sut.showPermissionAlert, "초기 상태에서 showPermissionAlert는 false여야 함")
    }

    // MARK: - 위치 업데이트 콜백 테스트
    func 위치가_업데이트되면_콜백이_호출되고_위치_정보가_전달된다() {
        // Given: 콜백 설정
        var callbackInvoked = false
        var receivedLocation: CLLocation?

        sut.onLocationUpdate = { location in
            callbackInvoked = true
            receivedLocation = location
        }

        // When: 위치 업데이트 시뮬레이션
        let testLocation = CLLocation(latitude: 37.5403, longitude: 127.0698)
        let mockManager = CLLocationManager()
        sut.locationManager(mockManager, didUpdateLocations: [testLocation])

        // Then: 콜백이 호출되고 위치가 업데이트됨
        XCTAssertTrue(callbackInvoked, "콜백이 호출되어야 함")
        XCTAssertNotNil(receivedLocation, "위치 정보가 전달되어야 함")
        XCTAssertEqual(receivedLocation?.coordinate.latitude, testLocation.coordinate.latitude)
        XCTAssertEqual(receivedLocation?.coordinate.longitude, testLocation.coordinate.longitude)
    }

    func refresh_없이_여러_번_위치_업데이트하면_콜백은_한_번만_호출된다() {
        // Given: 콜백 호출 횟수 추적
        var callbackCount = 0

        sut.onLocationUpdate = { _ in
            callbackCount += 1
        }

        // When: 여러 번 위치 업데이트 (refresh 없이)
        let testLocation1 = CLLocation(latitude: 37.5403, longitude: 127.0698)
        let testLocation2 = CLLocation(latitude: 37.5404, longitude: 127.0699)
        let mockManager = CLLocationManager()

        sut.locationManager(mockManager, didUpdateLocations: [testLocation1])
        sut.locationManager(mockManager, didUpdateLocations: [testLocation2])

        // Then: 콜백이 한 번만 호출되어야 함
        XCTAssertEqual(callbackCount, 1, "최초 위치 업데이트 시에만 콜백이 호출되어야 함")
    }

    func refresh_후_위치_업데이트하면_콜백이_다시_호출된다() {
        // Given: 콜백 설정
        var callbackCount = 0

        sut.onLocationUpdate = { _ in
            callbackCount += 1
        }

        // When: 첫 업데이트
        let testLocation1 = CLLocation(latitude: 37.5403, longitude: 127.0698)
        let mockManager = CLLocationManager()
        sut.locationManager(mockManager, didUpdateLocations: [testLocation1])

        // refresh 호출
        sut.refreshLocation()

        // 두 번째 업데이트
        let testLocation2 = CLLocation(latitude: 37.5404, longitude: 127.0699)
        sut.locationManager(mockManager, didUpdateLocations: [testLocation2])

        // Then: refresh 후 콜백이 다시 호출됨
        XCTAssertEqual(callbackCount, 2, "refresh 후에는 콜백이 다시 호출되어야 함")
    }

    // MARK: - currentLocation 업데이트 테스트
    func 위치가_업데이트되면_currentLocation이_업데이트된다() {
        // Given: 테스트 위치
        let testLocation = CLLocation(latitude: 37.5403, longitude: 127.0698)
        let mockManager = CLLocationManager()

        // When: 위치 업데이트
        sut.locationManager(mockManager, didUpdateLocations: [testLocation])

        // Then: currentLocation이 업데이트됨
        XCTAssertNotNil(sut.currentLocation)
        XCTAssertEqual(sut.currentLocation?.coordinate.latitude, testLocation.coordinate.latitude)
        XCTAssertEqual(sut.currentLocation?.coordinate.longitude, testLocation.coordinate.longitude)
    }

    func 여러_위치를_한_번에_업데이트하면_마지막_위치가_저장된다() {
        // Given: 여러 위치 (마지막 위치가 가장 정확함)
        let locations = [
            CLLocation(latitude: 37.5401, longitude: 127.0696),
            CLLocation(latitude: 37.5402, longitude: 127.0697),
            CLLocation(latitude: 37.5403, longitude: 127.0698)
        ]
        let mockManager = CLLocationManager()

        // When: 여러 위치를 한 번에 업데이트
        sut.locationManager(mockManager, didUpdateLocations: locations)

        // Then: 마지막 위치가 저장됨
        XCTAssertNotNil(sut.currentLocation)
        XCTAssertEqual(sut.currentLocation?.coordinate.latitude, locations.last?.coordinate.latitude)
        XCTAssertEqual(sut.currentLocation?.coordinate.longitude, locations.last?.coordinate.longitude)
    }

    // MARK: - 에러 처리 테스트
    func 위치_에러가_발생하면_크래시_없이_처리된다() {
        // Given: 에러 시뮬레이션
        let testError = NSError(domain: kCLErrorDomain, code: CLError.denied.rawValue, userInfo: nil)
        let mockManager = CLLocationManager()

        // When: 에러 발생
        // Then: 크래시 없이 처리되어야 함 (로그만 출력)
        XCTAssertNoThrow(sut.locationManager(mockManager, didFailWithError: testError))
    }

    // MARK: - refreshLocation 테스트
    func refresh_호출_후_다시_위치_업데이트를_받을_수_있다() {
        // Given: 첫 번째 위치 업데이트
        let testLocation1 = CLLocation(latitude: 37.5403, longitude: 127.0698)
        let mockManager = CLLocationManager()
        sut.locationManager(mockManager, didUpdateLocations: [testLocation1])

        // When: refresh 호출
        sut.refreshLocation()

        // Then: 다시 위치 업데이트를 받을 준비가 됨
        var callbackInvoked = false
        sut.onLocationUpdate = { _ in
            callbackInvoked = true
        }

        let testLocation2 = CLLocation(latitude: 37.5404, longitude: 127.0699)
        sut.locationManager(mockManager, didUpdateLocations: [testLocation2])

        XCTAssertTrue(callbackInvoked, "refresh 후 콜백이 다시 호출되어야 함")
    }

    // MARK: - 빈 배열 처리 테스트
    func 빈_위치_배열로_업데이트하면_콜백이_호출되지_않는다() {
        // Given: 빈 위치 배열
        let mockManager = CLLocationManager()
        var callbackInvoked = false

        sut.onLocationUpdate = { _ in
            callbackInvoked = true
        }

        // When: 빈 배열로 업데이트
        sut.locationManager(mockManager, didUpdateLocations: [])

        // Then: 콜백이 호출되지 않고 currentLocation도 nil
        XCTAssertFalse(callbackInvoked, "빈 배열일 때 콜백이 호출되지 않아야 함")
        XCTAssertNil(sut.currentLocation, "빈 배열일 때 currentLocation은 nil이어야 함")
    }
}
