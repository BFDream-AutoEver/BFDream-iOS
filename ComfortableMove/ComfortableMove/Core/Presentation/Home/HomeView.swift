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

    @State private var selectedBusID: String?
    @State private var busArrivals: [BusArrivalItem] = []
    @State private var isLoadingArrivals = false
    @State private var nearestStation: StationItem? // 가장 가까운 정류소
    @State private var isLoadingStation = false



    // 버튼 상태
    @State private var isButtonTapped = false
    @State private var isWaitingForBluetooth = false // Bluetooth 응답 대기 상태
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
                                .accessibilitySortPriority(5)

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

                    // 메인 콘텐츠 영역 (일부 스크롤 가능)
                    VStack(spacing: 30) {
                        // 중앙 버튼 영역
                        VStack(spacing: 16) {
                            Button(action: {
                                Logger.log(message: "🔘 중앙 버튼 클릭 - selectedBusID: \(selectedBusID ?? "nil"), isButtonTapped: \(isButtonTapped)")
                                if selectedBusID != nil && isButtonTapped {
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
                                    if isWaitingForBluetooth {
                                        // Bluetooth 응답 대기 중: 흰 바탕에 ProgressView
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 240, height: 240)
                                            .overlay(
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: Color("BFPrimaryColor")))
                                                    .scaleEffect(4.0)
                                            )
                                            .transition(.opacity)
                                    } else {
                                        // 일반 상태: 버튼 이미지 표시
                                        Image(isButtonTapped ? "buttonTappedImage" : "buttonImage")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 240, height: 240)
                                            .transition(.opacity)
                                    }
                                }
                                .animation(.easeInOut(duration: 0.3), value: isWaitingForBluetooth)
                            }
                            .disabled(isWaitingForBluetooth)
                            .accessibleLabel(
                                A11yLabels.notificationButton(selected: isButtonTapped, busName: selectedBusName),
                                hint: A11yLabels.notificationButtonHint(selected: isButtonTapped, busName: selectedBusName),
                                value: isButtonTapped ? A11yLabels.notificationButtonValueSelected : A11yLabels.notificationButtonValueUnselected,
                                traits: .isButton
                            )
                            .accessibilitySortPriority(1)

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
                                        .foregroundColor(.black)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .accessibleGroup(combine: true, label: A11yLabels.stationInfo(name: nearestStation?.stationNm ?? "찾는 중", distance: "100m 이내"))
                                .accessibilitySortPriority(4)

                                Spacer()

                                Button(action: {
                                    refreshLocation()
                                    UIAccessibility.post(notification: .announcement, argument: "위치 정보를 새로고침합니다")
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title2)
                                        .foregroundColor(Color("LightSecondary"))
                                        .padding(12) // 터치 영역 확보 (44pt 이상)
                                        .background(Color.white.opacity(0.01)) // 투명 배경으로 터치 영역 채움
                                        .rotationEffect(.degrees(isLoadingArrivals ? 360 : 0))
                                        .animation(isLoadingArrivals ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoadingArrivals)
                                }
                                .disabled(isLoadingArrivals)
                                .accessibleLabel(A11yLabels.refresh, hint: A11yLabels.refreshHint, traits: .isButton)
                                .accessibilitySortPriority(2)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)

                            Divider()

                            // 버스 노선들 (API에서 가져온 실시간 정보)
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(busArrivals) { arrivalInfo in
                                        VStack(spacing: 0) {
                                            HStack {
                                                // 버스 정보 (아이콘 + 텍스트)
                                                HStack {
                                                    Image(systemName: "bus")
                                                        .foregroundColor(arrivalInfo.busType.color)
                                                        .decorativeImage()

                                                    VStack(alignment: .leading, spacing: 4) {
                                                        HStack(spacing: 4) {
                                                            Text(arrivalInfo.rtNm)
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
                                                                    .foregroundColor(.black)
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
                                                                .foregroundColor(Color("LightSecondary"))
                                                                .fixedSize(horizontal: false, vertical: true)
                                                        }
                                                    }
                                                }
                                                .accessibleGroup(combine: true)
                                                .accessibilitySortPriority(3)

                                                Spacer()

                                                // 선택 버튼
                                                Button(action: {
                                                    // 새로운 노선 선택 시
                                                    if selectedBusID != arrivalInfo.id {
                                                        selectedBusID = arrivalInfo.id
                                                        isButtonTapped = true
                                                        HapticManager.shared.impact(style: .light)

                                                        let announcement = A11yLabels.busSelectedAnnouncement(
                                                            routeName: arrivalInfo.rtNm,
                                                            arrivalMsg: arrivalInfo.arrmsg1,
                                                            congestion: arrivalInfo.congestion != .unknown ? arrivalInfo.congestion.rawValue : nil,
                                                            direction: arrivalInfo.adirection
                                                        )
                                                        UIAccessibility.post(notification: .announcement, argument: announcement)
                                                    } else {
                                                        // 이미 선택된 것을 다시 누르면 선택 해제
                                                        selectedBusID = nil
                                                        isButtonTapped = false
                                                        UIAccessibility.post(notification: .announcement, argument: "선택이 해제되었습니다.")
                                                    }
                                                }) {
                                                    ZStack {
                                                        // 터치 영역 확장을 위한 투명 배경
                                                        Color.clear
                                                            .frame(width: 44, height: 44)

                                                        Circle()
                                                            .fill(selectedBusID == arrivalInfo.id ? arrivalInfo.busType.color : Color("LightSecondary"))
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
                                                    A11yLabels.busSelection(routeName: arrivalInfo.rtNm, isSelected: selectedBusID == arrivalInfo.id),
                                                    hint: A11yLabels.busSelectionHint(isSelected: selectedBusID == arrivalInfo.id),
                                                    value: A11yLabels.busSelectionValue(isSelected: selectedBusID == arrivalInfo.id),
                                                    traits: [.isButton, selectedBusID == arrivalInfo.id ? .isSelected : []]
                                                )
                                                .accessibilitySortPriority(3)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color.white)

                                            Divider()
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 240) // 3개 항목 높이로 제한 (항목당 약 80pt)
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16)
                        
                        Spacer()
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
        guard let selectedID = selectedBusID,
              let selectedBus = busArrivals.first(where: { $0.id == selectedID })
        else { return "" }
        return selectedBus.rtNm
    }
    
    // MARK: - 배려석 알림 전송
    private func sendCourtesySeatNotification() {
        Logger.log(message: "📲 sendCourtesySeatNotification 호출됨 - 버스: \(selectedBusName)")

        // Bluetooth 응답 대기 상태 시작
        isWaitingForBluetooth = true

        bluetoothManager.sendCourtesySeatNotification(busNumber: selectedBusName, withSound: isSoundEnabled) { result in
            DispatchQueue.main.async {
                Logger.log(message: "📲 Bluetooth 전송 결과: \(result)")

                // Bluetooth 응답 대기 상태 종료 및 버튼 상태 초기화 (Alert 표시 전에 먼저 처리)
                isWaitingForBluetooth = false
                resetButtonState()

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
            }
        }
    }
    
    // MARK: - 버튼 상태 초기화
    private func resetButtonState() {
        isButtonTapped = false
        selectedBusID = nil
    }

    // MARK: - 위치 새로고침
    private func refreshLocation() {
        // 버튼 상태 초기화
        resetButtonState()

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

                // 딕셔너리 변환 대신 배열을 직접 사용하고, 노선명 순으로 정렬
                busArrivals = items.sorted { $0.rtNm < $1.rtNm }

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
