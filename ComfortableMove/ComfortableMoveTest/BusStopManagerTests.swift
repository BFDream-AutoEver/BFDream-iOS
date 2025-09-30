//
//  BusStopManagerTests.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/30/25.
//

import XCTest
import CoreLocation
@testable import ComfortableMove

final class BusStopManagerTests: XCTestCase {
    var sut: BusStopManager!

    override func setUp() {
        super.setUp()
        sut = BusStopManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 초기화 테스트
    func 초기_상태에서_nearestStop은_nil이고_isLoading은_false이다() {
        // Given & When: BusStopManager 초기화 (setUp에서 수행됨)

        // Then: 초기 상태 확인
        XCTAssertNil(sut.nearestStop, "초기 상태에서 nearestStop은 nil이어야 함")
        XCTAssertFalse(sut.isLoading, "초기 상태에서 isLoading은 false여야 함")
    }

    // MARK: - 가까운 정류장 찾기 테스트
    func 유효한_위치에서_가까운_정류장을_찾으면_정류장_정보를_반환한다() {
        // Given: 서울 건대입구역 근처 좌표
        let testLocation = CLLocation(latitude: 37.5403, longitude: 127.0698)
        let expectation = XCTestExpectation(description: "정류장 검색 완료")

        // When: 가까운 정류장 찾기
        sut.findNearestStop(userLocation: testLocation)

        // Then: isLoading이 true로 변경됨
        XCTAssertTrue(sut.isLoading, "검색 중에는 isLoading이 true여야 함")

        // 비동기 작업 완료 대기
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertFalse(self.sut.isLoading, "검색 완료 후 isLoading은 false여야 함")
            XCTAssertNotNil(self.sut.nearestStop, "정류장을 찾아야 함")

            if let nearestStop = self.sut.nearestStop {
                XCTAssertFalse(nearestStop.stopName.isEmpty, "정류장 이름이 있어야 함")
                XCTAssertFalse(nearestStop.routes.isEmpty, "버스 노선이 있어야 함")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    func 동일한_위치로_여러_번_검색하면_같은_정류장을_반환한다() {
        // Given: 동일한 위치
        let testLocation = CLLocation(latitude: 37.5403, longitude: 127.0698)
        let expectation = XCTestExpectation(description: "여러 번 검색 완료")

        // When: 같은 위치로 두 번 검색
        sut.findNearestStop(userLocation: testLocation)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let firstResult = self.sut.nearestStop

            self.sut.findNearestStop(userLocation: testLocation)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let secondResult = self.sut.nearestStop

                // Then: 같은 결과가 나와야 함
                XCTAssertEqual(firstResult?.stopName, secondResult?.stopName, "같은 위치는 같은 정류장을 반환해야 함")
                XCTAssertEqual(firstResult?.routes.count, secondResult?.routes.count, "버스 노선 개수가 같아야 함")

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 4.0)
    }

    func 서로_다른_위치로_검색하면_다른_정류장을_반환한다() {
        // Given: 서로 다른 두 위치
        let location1 = CLLocation(latitude: 37.5403, longitude: 127.0698) // 건대입구역
        let location2 = CLLocation(latitude: 37.5665, longitude: 126.9780) // 시청역
        let expectation = XCTestExpectation(description: "다른 위치 검색 완료")

        // When: 첫 번째 위치 검색
        sut.findNearestStop(userLocation: location1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let firstResult = self.sut.nearestStop

            // When: 두 번째 위치 검색
            self.sut.findNearestStop(userLocation: location2)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let secondResult = self.sut.nearestStop

                // Then: 다른 정류장이 나와야 함
                XCTAssertNotNil(firstResult)
                XCTAssertNotNil(secondResult)
                XCTAssertNotEqual(firstResult?.stopName, secondResult?.stopName, "다른 위치는 다른 정류장을 반환해야 함")

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 4.0)
    }

    // MARK: - 로딩 상태 테스트
    func 정류장_검색_시작하면_isLoading이_true가_되고_완료_후_false가_된다() {
        // Given: 테스트 위치
        let testLocation = CLLocation(latitude: 37.5403, longitude: 127.0698)
        let expectation = XCTestExpectation(description: "로딩 상태 변경 확인")

        // When: 검색 시작
        sut.findNearestStop(userLocation: testLocation)

        // Then: 즉시 isLoading이 true가 됨
        XCTAssertTrue(sut.isLoading)

        // 완료 후 isLoading이 false로 변경됨
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertFalse(self.sut.isLoading)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - 성능 테스트
    func 가까운_정류장_찾기_성능_측정() {
        let testLocation = CLLocation(latitude: 37.5403, longitude: 127.0698)

        measure {
            let expectation = XCTestExpectation(description: "성능 테스트")

            sut.findNearestStop(userLocation: testLocation)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 2.0)
        }
    }
}
