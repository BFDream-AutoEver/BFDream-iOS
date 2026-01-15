//
//  HomeView.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/17/25.
//

import SwiftUI
import CoreLocation

struct HomeView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var alertManager = AlertManager()

    @State private var selectedRouteName: String?
    @State private var busArrivals: [String: BusArrivalItem] = [:] // routeName: 도착정보
    @State private var isLoadingArrivals = false
    @State private var nearestStation: StationItem? // 가장 가까운 정류소
    @State private var isLoadingStation = false



    // 버튼 상태
    @State private var isButtonTapped = false
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true

    // 자동 새로고침 타이머 (1분마다)
    private let autoRefreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()


    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                VStack(spacing: 0) {
                    // 상단 헤더
                    VStack(spacing: 0) {
                        // 상태바 영역
                        Rectangle()
                            .fill(Color("BFPrimaryColor"))
                            .frame(height: geometry.safeAreaInsets.top)
                    
                        // 네비게이션 헤더
                        HStack {
                            Image("HomeTitle")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 28)
                                .accessibleLabel(A11yLabels.appLogo)
                            
                            Spacer()
                            
                            HStack(spacing: 10) {
                                NavigationLink(destination: HelpPageView()) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(8) // 터치 영역 확보
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    HapticManager.shared.impact(style: .light)
                                })
                                .accessibleLabel(A11yLabels.help, hint: A11yLabels.helpHint, traits: .isButton)

                                NavigationLink(destination: InfoView()) {
                                    Image(systemName: "gearshape")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(8) // 터치 영역 확보
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    HapticManager.shared.impact(style: .light)
                                })
                                .accessibleLabel(A11yLabels.settings, hint: A11yLabels.settingsHint, traits: .isButton)
                            }
                        }
                        .padding(.horizontal, 16) // 패딩 조정
                        .padding(.vertical, 16)
                        .background(Color("BFPrimaryColor"))
                    }

                    // 메인 콘텐츠 영역 (스크롤 가능)
                    ScrollView {
                        VStack(spacing: 30) {
                            // 중앙 버튼 영역
                            VStack(spacing: 16) {
                                Button(action: {
                                    Logger.log(message: "🔘 중앙 버튼 클릭 - selectedRouteName: \(selectedRouteName ?? "nil"), isButtonTapped: \(isButtonTapped)")
                                    if selectedRouteName != nil && isButtonTapped {
                                        HapticManager.shared.impact(style: .medium)
                                        Logger.log(message: "✅ 확인 Alert 표시")
                                        alertManager.showAlert(.bluetoothConfirm(
                                            busName: selectedBusName,
                                            onConfirm: { sendCourtesySeatNotification() },
                                            onCancel: { resetButtonState() }
                                        ))
                                    } else {
                                        HapticManager.shared.notification(type: .warning)
                                    }
                                }) {
                                    ZStack {
                                        Image(isButtonTapped ? "buttonTappedImage" : "buttonImage")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 240, height: 240)
                                    }
                                }
                                .accessibleLabel(
                                    A11yLabels.notificationButton(selected: isButtonTapped, busName: selectedBusName),
                                    hint: A11yLabels.notificationButtonHint(selected: isButtonTapped, busName: selectedBusName),
                                    value: isButtonTapped ? A11yLabels.notificationButtonValueSelected : A11yLabels.notificationButtonValueUnselected,
                                    traits: .isButton
                                )

                                // 버튼 아래 텍스트
                                Text(isButtonTapped ? "선택 완료! 알림을 울려주세요" : "버스 선택 후, 알림을 울려주세요!")
                                    .moveFont(.homeSubTitle)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true) // 줄바꿈 허용
                                    .accessibilityHidden(true)
                            }
                            .padding(.top, 20)
                            
                            // 하단 버스 정보 리스트 카드
                            VStack(spacing: 0) {
                                // 첫 번째 칸 - 정류장 정보
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(nearestStation?.stationNm ?? "정류장을 찾는 중...")
                                            .moveFont(.homeSubTitle)
                                            .foregroundColor(.black)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text("사용자와 100m 이내의 버스정류장 정보가 표시됩니다.")
                                            .moveFont(.caption)
                                            .foregroundColor(.gray)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .accessibleGroup(combine: true, label: A11yLabels.stationInfo(name: nearestStation?.stationNm ?? "찾는 중", distance: "100m 이내"))

                                    Spacer()

                                    Button(action: {
                                        refreshLocation()
                                        UIAccessibility.post(notification: .announcement, argument: "위치 정보를 새로고침합니다")
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.title2)
                                            .foregroundColor(.gray)
                                            .padding(12) // 터치 영역 확보 (44pt 이상)
                                            .background(Color.white.opacity(0.01)) // 투명 배경으로 터치 영역 채움
                                            .rotationEffect(.degrees(isLoadingArrivals ? 360 : 0))
                                            .animation(isLoadingArrivals ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoadingArrivals)
                                    }
                                    .disabled(isLoadingArrivals)
                                    .accessibleLabel(A11yLabels.refresh, hint: A11yLabels.refreshHint, traits: .isButton)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)

                                Divider()

                                // 버스 노선들 (API에서 가져온 실시간 정보)
                                ForEach(Array(busArrivals.keys.sorted()), id: \.self) { routeName in
                                    if let arrivalInfo = busArrivals[routeName] {
                                        VStack(spacing: 0) {
                                            HStack {
                                                // 버스 정보 (아이콘 + 텍스트)
                                                HStack {
                                                    Image(systemName: "bus")
                                                        .foregroundColor(arrivalInfo.busType.color)
                                                        .decorativeImage()

                                                    VStack(alignment: .leading, spacing: 4) {
                                                        HStack(spacing: 4) {
                                                            Text(routeName)
                                                                .moveFont(.homeSubTitle)
                                                                .foregroundColor(arrivalInfo.busType.color)
                                                                .fontWeight(.bold)
                                                                .layoutPriority(1) // 버스 번호 우선 표시

                                                            if !arrivalInfo.busType.displayName.isEmpty {
                                                                Text(arrivalInfo.busType.displayName)
                                                                    .moveFont(.caption)
                                                                    .foregroundColor(.gray)
                                                            }
                                                        }

                                                        HStack(spacing: 4) {
                                                            if let arrivalMsg = arrivalInfo.arrmsg1 {
                                                                Text(arrivalMsg)
                                                                    .moveFont(.caption)
                                                                    .foregroundColor(.gray)
                                                                    .fixedSize(horizontal: false, vertical: true)
                                                            }

                                                            if arrivalInfo.congestion != .unknown {
                                                                Text(arrivalInfo.congestion.rawValue)
                                                                    .moveFont(.caption)
                                                                    .foregroundColor(arrivalInfo.congestion.color)
                                                            }
                                                        }

                                                        if let direction = arrivalInfo.adirection {
                                                            Text("\(direction) 방면")
                                                                .moveFont(.caption)
                                                                .foregroundColor(.gray.opacity(0.8))
                                                                .fixedSize(horizontal: false, vertical: true)
                                                        }
                                                    }
                                                }
                                                .accessibleGroup(combine: true)

                                                Spacer()

                                                // 선택 버튼
                                                Button(action: {
                                                    // 새로운 노선 선택 시
                                                    if selectedRouteName != routeName {
                                                        selectedRouteName = routeName
                                                        isButtonTapped = true
                                                        HapticManager.shared.impact(style: .light)
                                                        
                                                        let announcement = A11yLabels.busSelectedAnnouncement(
                                                            routeName: routeName,
                                                            arrivalMsg: arrivalInfo.arrmsg1,
                                                            congestion: arrivalInfo.congestion != .unknown ? arrivalInfo.congestion.rawValue : nil,
                                                            direction: arrivalInfo.adirection
                                                        )
                                                        UIAccessibility.post(notification: .announcement, argument: announcement)
                                                    } else {
                                                        // 이미 선택된 것을 다시 누르면 선택 해제
                                                        selectedRouteName = nil
                                                        isButtonTapped = false
                                                        UIAccessibility.post(notification: .announcement, argument: "선택이 해제되었습니다.")
                                                    }
                                                }) {
                                                    ZStack {
                                                        // 터치 영역 확장을 위한 투명 배경
                                                        Color.clear
                                                            .frame(width: 44, height: 44)
                                                        
                                                        Circle()
                                                            .fill(selectedRouteName == routeName ? arrivalInfo.busType.color : Color.gray.opacity(0.3))
                                                            .frame(width: 24, height: 24)
                                                            .overlay(
                                                                Image(systemName: "checkmark")
                                                                    .font(.system(size: 12, weight: .bold))
                                                                    .foregroundColor(.white)
                                                            )
                                                    }
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .accessibleLabel(
                                                    A11yLabels.busSelection(routeName: routeName, isSelected: selectedRouteName == routeName),
                                                    hint: A11yLabels.busSelectionHint(isSelected: selectedRouteName == routeName),
                                                    value: A11yLabels.busSelectionValue(isSelected: selectedRouteName == routeName),
                                                    traits: [.isButton, selectedRouteName == routeName ? .isSelected : []]
                                                )
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color.white)

                                            Divider()
                                        }
                                    }
                                }
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 16)
                            
                            Spacer(minLength: 40)
                        }
                    }
                }
                .background(Color("BFPrimaryColor"))
                .ignoresSafeArea(.all, edges: .top)
                .onAppear {
                    setupAlertCallbacks()
                    locationManager.requestPermission()
                    Logger.log(message: "🔔 [HomeView] 알림음 설정: \(isSoundEnabled ? "ON" : "OFF")")
                }
                .onChange(of: locationManager.currentLocation) { _, newLocation in
                    if let location = newLocation {
                        findNearestStation(location: location)
                    }
                }
                .onChange(of: locationManager.showPermissionAlert) { _, shouldShow in
                    if shouldShow {
                        alertManager.showAlert(.locationUnauthorized)
                    }
                }
                .onChange(of: nearestStation) { _, newStation in
                    if newStation != nil {
                        refreshBusArrivals()
                        if let stationName = newStation?.stationNm {
                            UIAccessibility.post(notification: .announcement, argument: "\(stationName) 정류장 정보를 불러왔습니다")
                        }
                    }
                }
                .alert(item: $alertManager.currentAlert) { alertType in
                    createAlert(for: alertType)
                }
                .onReceive(autoRefreshTimer) { _ in
                    // 1분마다 버스 도착 정보 자동 새로고침
                    if nearestStation != nil {
                        refreshBusArrivals()
                    }
                }
                .navigationBarHidden(true)
            }
        }
    }

    // MARK: - Create Alert
    private func createAlert(for alertType: AlertType) -> Alert {
        if case .bluetoothConfirm(_, let onConfirm, let onCancel) = alertType {
            return Alert(
                title: Text(alertType.title),
                primaryButton: .default(Text("확인")) {
                    alertManager.dismissAlert()
                    onConfirm()
                },
                secondaryButton: .cancel(Text("취소")) {
                    alertManager.dismissAlert()
                    onCancel()
                }
            )
        }

        if alertType.shouldBlockApp {
            return Alert(
                title: Text(alertType.title),
                message: Text(alertType.message),
                primaryButton: .default(Text(alertType.primaryButtonText)) {
                    alertManager.openSettings()
                },
                secondaryButton: .cancel(Text("취소"))
            )
        }

        let messageText: Text? = alertType.message.isEmpty ? nil : Text(alertType.message)
        return Alert(
            title: Text(alertType.title),
            message: messageText,
            dismissButton: .default(Text(alertType.primaryButtonText)) {
                alertManager.dismissAlert()
            }
        )
    }

    // MARK: - Setup Alert Callbacks
    private func setupAlertCallbacks() {
        bluetoothManager.onBluetoothUnsupported = {
            alertManager.showAlert(.bluetoothUnsupported)
        }

        bluetoothManager.onBluetoothUnauthorized = {
            alertManager.showAlert(.bluetoothUnauthorized)
        }
    }
    
    // MARK: - Computed Properties
    private var selectedBusName: String {
        return selectedRouteName ?? ""
    }
    
    // MARK: - 배려석 알림 전송
    private func sendCourtesySeatNotification() {
        Logger.log(message: "📲 sendCourtesySeatNotification 호출됨 - 버스: \(selectedBusName)")
        bluetoothManager.sendCourtesySeatNotification(busNumber: selectedBusName, withSound: isSoundEnabled) { result in
            DispatchQueue.main.async {
                Logger.log(message: "📲 Bluetooth 전송 결과: \(result)")
                
                switch result {
                case .success:
                    HapticManager.shared.notification(type: .success)
                    alertManager.showAlert(.bluetoothSuccess)
                case .deviceNotFound:
                    // 기기를 찾지 못했거나 설정 오류인 경우
                    HapticManager.shared.notification(type: .warning)
                    alertManager.showAlert(.busDeviceNotFound)
                case .failure:
                    // 통신 중 에러가 발생한 경우
                    HapticManager.shared.notification(type: .error)
                    alertManager.showAlert(.bluetoothFailure)
                }
                
                // 알림 전송 시도 후 초기화
                resetButtonState()
            }
        }
    }
    
    // MARK: - 버튼 상태 초기화
    private func resetButtonState() {
        isButtonTapped = false
        selectedRouteName = nil
    }

    // MARK: - 위치 새로고침
    private func refreshLocation() {
        guard let location = locationManager.currentLocation else {
            locationManager.refreshLocation()
            return
        }
        findNearestStation(location: location)
    }

    // MARK: - 가장 가까운 정류소 찾기
    private func findNearestStation(location: CLLocation) {
        isLoadingStation = true

        Task {
            do {
                let stations = try await BusStopService.shared.getNearbyStations(location: location, radius: 100)

                // 가장 가까운 정류소 선택
                if let nearest = stations.first {
                    nearestStation = nearest
                    Logger.log(message: "📍 [HomeView] Nearest station: \(nearest.stationNm) (\(nearest.dist)m)")
                } else {
                    Logger.log(message: "⚠️ [HomeView] No stations found within radius")
                    nearestStation = nil
                }
            } catch let error as NSError {
                Logger.log(message: "❌ [HomeView] Failed to find nearest station: \(error)")

                // 서울 외 지역 체크
                if error.domain == "noBusInfo" {
                    alertManager.showAlert(.noBusInfo)
                } else {
                    alertManager.showAlert(.apiError)
                }
                nearestStation = nil
            }

            isLoadingStation = false
        }
    }

    // MARK: - 버스 도착 정보 새로고침
    private func refreshBusArrivals() {
        guard let station = nearestStation else { return }

        isLoadingArrivals = true

        Task {
            do {
                let items = try await BusArrivalService.shared.getStationArrivalInfo(arsId: station.arsId)

                // 딕셔너리로 변환
                var newArrivals: [String: BusArrivalItem] = [:]
                for item in items {
                    newArrivals[item.rtNm] = item
                }

                busArrivals = newArrivals

            } catch let error as NSError {
                Logger.log(message: "❌ [HomeView] Failed to fetch arrival info: \(error)")

                // API 에러 처리
                if error.domain == "APIError" {
                    alertManager.showAlert(.apiError)
                }
            }

            isLoadingArrivals = false
        }
    }
}

#Preview {
    HomeView()
}
