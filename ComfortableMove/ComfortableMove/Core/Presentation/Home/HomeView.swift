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

    @State private var selectedRouteName: String?
    @State private var busArrivals: [String: BusArrivalItem] = [:] // routeName: 도착정보
    @State private var isLoadingArrivals = false
    @State private var nearestStation: StationItem? // 가장 가까운 정류소
    @State private var isLoadingStation = false
    
    // Alert 상태
    @State private var showConfirmAlert = false
    @State private var showSuccessAlert = false
    @State private var showFailureAlert = false
    
    // 화면 표시 상태
    @State private var showHelpPage = false
    
    // 버튼 상태
    @State private var isButtonTapped = false
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 헤더
                VStack(spacing: 0) {
                    // 상태바 영역
                    Rectangle()
                        .fill(Color("BFPrimaryColor"))
                        .frame(height: 44)
                    
                    // 네비게이션 헤더
                    HStack {
                        Image("HomeTitle")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 28)
                        
                        Spacer()
                        
                        HStack(spacing: 10) {
                            Button(action: {
                                showHelpPage = true
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            NavigationLink(destination: InfoView()) {
                                Image(systemName: "gearshape")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color("BFPrimaryColor"))
                }
                
                Spacer()
                
                VStack(spacing: 30) {
                    // 중앙 버튼
                    Button(action: {
                        if selectedRouteName != nil && isButtonTapped {
                            showConfirmAlert = true
                        }
                    }) {
                        ZStack {
                            Image(isButtonTapped ? "buttonTappedImage" : "buttonImage")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 240, height: 240)
                        }
                    }
                    .padding(.top, 40)
                    
                    // 버튼 아래 텍스트
                    Text(isButtonTapped ? "선택 완료! 알림을 울려주세요" : "버스 선택 후, 알림을 울려주세요!")
                        .moveFont(.homeSubTitle)
                        .foregroundColor(.white)
                }
                
                List {
                    // 첫 번째 칸 - 정류장 정보
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(nearestStation?.stationNm ?? "정류장을 찾는 중...")
                                .moveFont(.homeSubTitle)
                                .foregroundColor(.black)

                            Text("사용자와 최근접의 버스정류장 정보가 표시됩니다.")
                                .moveFont(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            refreshBusArrivals()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .rotationEffect(.degrees(isLoadingArrivals ? 360 : 0))
                                .animation(isLoadingArrivals ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoadingArrivals)
                        }
                        .disabled(isLoadingArrivals)
                    }
                    .padding(.vertical, 4)
                    
                    // 버스 노선들 (API에서 가져온 실시간 정보)
                    ForEach(Array(busArrivals.keys.sorted()), id: \.self) { routeName in
                        if let arrivalInfo = busArrivals[routeName] {
                            HStack {
                                Image(systemName: "bus")
                                    .foregroundColor(arrivalInfo.busType.color)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(routeName)
                                            .moveFont(.homeSubTitle)
                                            .foregroundColor(arrivalInfo.busType.color)
                                            .fontWeight(.bold)

                                        if !arrivalInfo.busType.displayName.isEmpty {
                                            Text(arrivalInfo.busType.displayName)
                                                .moveFont(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    if let arrivalMsg = arrivalInfo.arrmsg1 {
                                        Text(arrivalMsg)
                                            .moveFont(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    if let direction = arrivalInfo.adirection {
                                        Text("\(direction) 방면")
                                            .moveFont(.caption)
                                            .foregroundColor(.gray.opacity(0.8))
                                    }
                                }

                                Spacer()

                                Button(action: {
                                    // 새로운 노선 선택 시
                                    if selectedRouteName != routeName {
                                        selectedRouteName = routeName
                                        isButtonTapped = true  // 리스트 선택 시 중앙 버튼 이미지/텍스트 변경
                                    } else {
                                        // 이미 선택된 것을 다시 누르면 선택 해제
                                        selectedRouteName = nil
                                        isButtonTapped = false
                                    }
                                }) {
                                    Circle()
                                        .fill(selectedRouteName == routeName ? arrivalInfo.busType.color : Color.gray.opacity(0.3))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 8)
                            .alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
                .scrollDisabled(busArrivals.count <= 3)
                .scrollIndicators(.hidden)
                .padding(.top, 30)
                
                Spacer()
            }
            .background(Color("BFPrimaryColor"))
            .ignoresSafeArea(.all, edges: .top)
            .onAppear {
                locationManager.requestPermission()
            }
            .onChange(of: locationManager.currentLocation) { newLocation in
                if let location = newLocation {
                    findNearestStation(location: location)
                }
            }
            .onChange(of: nearestStation) { newStation in
                if newStation != nil {
                    refreshBusArrivals()
                }
            }
            .alert(isPresented: $showConfirmAlert) {
                Alert(
                    title: Text("\(selectedBusName)버스에 배려석 알림을 전송하시겠습니까?"),
                    primaryButton: .destructive(Text("취소")) {
                        resetButtonState()
                    },
                    secondaryButton: .default(Text("확인")) {
                        sendCourtesySeatNotification()
                    }
                )
            }
            .alert("알림 전송 완료", isPresented: $showSuccessAlert) {
                Button("확인", role: .cancel) { }
            }
            .alert("버스 배려석 알림 전송에 실패하였습니다.", isPresented: $showFailureAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("다시 한번 시도해주세요.")
            }
            .overlay(
                showHelpPage ? HelpPageView(isPresented: $showHelpPage) : nil
            )
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Computed Properties
    private var selectedBusName: String {
        return selectedRouteName ?? ""
    }
    
    // MARK: - 배려석 알림 전송
    private func sendCourtesySeatNotification() {
        bluetoothManager.sendCourtesySeatNotification(busNumber: selectedBusName) {  success in
            if success {
                showSuccessAlert = true
            } else {
                showFailureAlert = true
            }
            // 알림 전송 완료/실패 후 초기화
            resetButtonState()
        }
    }
    
    // MARK: - 버튼 상태 초기화
    private func resetButtonState() {
        isButtonTapped = false
        selectedRouteName = nil
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
            } catch {
                Logger.log(message: "❌ [HomeView] Failed to find nearest station: \(error)")
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
            } catch {
                Logger.log(message: "❌ [HomeView] Failed to fetch arrival info: \(error)")
            }

            isLoadingArrivals = false
        }
    }
}

#Preview {
    HomeView()
}
