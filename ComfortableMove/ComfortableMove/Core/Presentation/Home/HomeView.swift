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
                    headerSection(topInset: geometry.safeAreaInsets.top)
                    mainContentSection
                    
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

    // MARK: - Header Section
    private func headerSection(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            // 상태바 영역
            Rectangle()
                .fill(Color("BFPrimaryColor"))
                .frame(height: topInset)

            // 네비게이션 헤더
            HStack {
                Image("HomeTitle")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 28)
                    .accessibleLabel(A11yLabels.appLogo)
                    .accessibilitySortPriority(5)

                Spacer()

                headerButtons
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color("BFPrimaryColor"))
        }
    }

    private var headerButtons: some View {
        HStack(spacing: 10) {
            NavigationLink(destination: HelpPageView()) {
                Image(systemName: "questionmark.circle")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
            }
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.impact(style: .light)
            })
            .accessibleLabel(A11yLabels.help, hint: A11yLabels.helpHint, traits: .isButton)

            NavigationLink(destination: InfoView()) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
            }
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.impact(style: .light)
            })
            .accessibleLabel(A11yLabels.settings, hint: A11yLabels.settingsHint, traits: .isButton)
        }
    }

    // MARK: - Main Content Section
    private var mainContentSection: some View {
        VStack(spacing: 30) {
            centerButtonSection
            busInfoCardSection
            Spacer()
        }
    }

    // MARK: - Center Button Section
    private var centerButtonSection: some View {
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
                    alertManager.showAlert(.busNotSelected)
                }
            }) {
                centerButtonContent
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
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
        }
        .padding(.top, 20)
    }

    private var centerButtonContent: some View {
        ZStack {
            if isWaitingForBluetooth {
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
                Image(isButtonTapped ? "buttonTappedImage" : "buttonImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 240, height: 240)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isWaitingForBluetooth)
    }

    // MARK: - Bus Info Card Section
    private var busInfoCardSection: some View {
        VStack(spacing: 0) {
            stationInfoRow
            Divider()
            busArrivalList
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
    }

    private var stationInfoRow: some View {
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
                    .padding(12)
                    .background(Color.white.opacity(0.01))
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
    }

    private var busArrivalList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(busArrivals) { arrivalInfo in
                    busArrivalRow(arrivalInfo)
                }
            }
        }
        .frame(maxHeight: 240)
    }

    private func busArrivalRow(_ arrivalInfo: BusArrivalItem) -> some View {
        VStack(spacing: 0) {
            HStack {
                busInfoLabel(arrivalInfo)
                Spacer()
                busSelectionButton(arrivalInfo)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)

            Divider()
        }
    }

    private func busInfoLabel(_ arrivalInfo: BusArrivalItem) -> some View {
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
                        .layoutPriority(1)

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
    }

    private func busSelectionButton(_ arrivalInfo: BusArrivalItem) -> some View {
        Button(action: {
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
                selectedBusID = nil
                isButtonTapped = false
                UIAccessibility.post(notification: .announcement, argument: "선택이 해제되었습니다.")
            }
        }) {
            ZStack {
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
            A11yLabels.busSelection(
                routeName: arrivalInfo.rtNm,
                busType: arrivalInfo.busType.displayName,
                arrivalMsg: arrivalInfo.arrmsg1,
                congestion: arrivalInfo.congestion != .unknown ? arrivalInfo.congestion.rawValue : nil,
                direction: arrivalInfo.adirection,
                isSelected: selectedBusID == arrivalInfo.id
            ),
            hint: A11yLabels.busSelectionHint(isSelected: selectedBusID == arrivalInfo.id),
            value: A11yLabels.busSelectionValue(isSelected: selectedBusID == arrivalInfo.id),
            traits: [.isButton, selectedBusID == arrivalInfo.id ? .isSelected : []]
        )
        .accessibilitySortPriority(3)
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

        // 백엔드 boarding 기록용 컨텍스트 캡처 (resetButtonState 이전에 확보)
        let busName = selectedBusName
        let routeType = busArrivals.first(where: { $0.id == selectedBusID })?.busType.displayName
        let stationSnapshot = nearestStation
        let coordinate = locationManager.currentLocation?.coordinate
        let soundEnabled = isSoundEnabled

        // BLE 스캔/송신 대상 = 화면에서 선택한 노선. 한글 노선명은 BluetoothManager 내부(DistrictMapper)
        // 에서 영문으로 변환되어 BF_DREAM_<영문> 기기와 매칭된다 (예: 강동01 → Gangdong01).
        // 기록용 busDeviceId 도 실제 기기명과 일치하도록 동일한 변환값을 사용한다.
        let bleBusNumber = busName
        let translatedBusNumber = DistrictMapper.shared.translateBusNumber(busName)
        let busDeviceId = "BF_DREAM_\(translatedBusNumber)"

        bluetoothManager.sendCourtesySeatNotification(busNumber: bleBusNumber, withSound: soundEnabled) { result in
            DispatchQueue.main.async {
                Logger.log(message: "📲 Bluetooth 전송 결과: \(result)")

                // Bluetooth 응답 대기 상태 종료 및 버튼 상태 초기화 (Alert 표시 전에 먼저 처리)
                isWaitingForBluetooth = false
                resetButtonState()

                // 백엔드 boarding/record 비동기 기록 (UX 차단 X — fire-and-forget)
                let status = BoardingRecordService.NotificationStatus.from(result)
                Task.detached(priority: .background) {
                    await BoardingRecordService.shared.record(
                        routeName: busName,
                        routeType: routeType,
                        busDeviceId: busDeviceId,
                        station: stationSnapshot,
                        latitude: coordinate?.latitude,
                        longitude: coordinate?.longitude,
                        soundEnabled: soundEnabled,
                        status: status
                    )
                }

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
                let stations = try await BusStopService.shared.getNearbyStations(location: location, radius: 500)

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
            var fetched: [BusArrivalItem] = []
            do {
                fetched = try await BusArrivalService.shared.getStationArrivalInfo(arsId: station.arsId)
            } catch let error as NSError {
                Logger.log(message: "❌ [HomeView] Failed to fetch arrival info: \(error)")
            }

            // 실제 도착 정보를 노선명 순으로 정렬
            busArrivals = fetched.sorted { $0.rtNm < $1.rtNm }

            isLoadingArrivals = false
        }
    }
}

#Preview {
    HomeView()
}
