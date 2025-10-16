//
//  HomeView.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/17/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var busStopManager = BusStopManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var bluetoothManager = BluetoothManager()

    @State private var selectedRouteId: Int?
    @State private var busArrivals: [Int: String] = [:] // routeId: 도착메시지
    @State private var isLoadingArrivals = false

    // Alert 상태
    @State private var showConfirmAlert = false
    @State private var showSuccessAlert = false
    @State private var showFailureAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더
            VStack(spacing: 0) {
                // 상태바 영역
                Rectangle()
                    .fill(Color("BFPrimaryColor"))
                    .frame(height: 44)
                
                // 네비게이션 헤더
                HStack {
                    Text("맘편한 이동")
                        .moveFont(.homeMediumTitle)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            // 도움말 액션 -> HelpPageView로
                        }) {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            // 설정 액션 -> InfoView로
                        }) {
                            Image(systemName: "gearshape")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color("BFPrimaryColor"))
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                // 중앙 버튼
                Button(action: {
                    if selectedRouteId != nil {
                        showConfirmAlert = true
                    }
                }) {
                    ZStack {
                        Image("buttonImage")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 225, height: 225)
                    }
                }
                .padding(.top, 40)
                
                // 버튼 아래 텍스트
                Text("버스 선택 후, 여기를 눌러주세요!")
                    .moveFont(.caption)
                    .foregroundColor(.gray)
            }
            
            List {
                // 첫 번째 칸 - 정류장 정보
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(busStopManager.nearestStop?.stopName ?? "정류장을 찾는 중...")
                            .moveFont(.homeSubTitle)
                            .foregroundColor(.black)

                        Text(busStopManager.nearestStop?.direction ?? "")
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
                    .disabled(isLoadingArrivals || busStopManager.nearestStop == nil)
                }
                .padding(.vertical, 4)

                // 버스 노선들
                if let routes = busStopManager.nearestStop?.routes {
                    ForEach(routes, id: \.routeId) { route in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(route.routeName)
                                    .moveFont(.homeSubTitle)
                                    .foregroundColor(.blue)
                                    .fontWeight(.bold)

                                if let arrivalMsg = busArrivals[route.routeId] {
                                    Text(arrivalMsg)
                                        .moveFont(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            Button(action: {
                                selectedRouteId = route.routeId
                            }) {
                                Circle()
                                    .fill(selectedRouteId == route.routeId ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .opacity(selectedRouteId == route.routeId ? 1 : 0)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
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
                busStopManager.findNearestStop(userLocation: location)
            }
        }
        .onChange(of: busStopManager.nearestStop) { newStop in
            if newStop != nil {
                refreshBusArrivals()
            }
        }
        .alert(isPresented: $showConfirmAlert) {
            Alert(
                title: Text("\(selectedBusName)버스에 배려석 알림을 전송하시겠습니까?"),
                primaryButton: .destructive(Text("취소")),
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
    }

    // MARK: - Computed Properties
    private var selectedBusName: String {
        guard let routeId = selectedRouteId,
              let routes = busStopManager.nearestStop?.routes,
              let selectedRoute = routes.first(where: { $0.routeId == routeId }) else {
            return ""
        }
        return selectedRoute.routeName
    }

    // MARK: - 배려석 알림 전송
    private func sendCourtesySeatNotification() {
        bluetoothManager.sendCourtesySeatNotification(busNumber: selectedBusName) { success in
            if success {
                showSuccessAlert = true
            } else {
                showFailureAlert = true
            }
        }
    }

    // MARK: - 버스 도착 정보 새로고침
    private func refreshBusArrivals() {
        guard let stop = busStopManager.nearestStop else { return }

        isLoadingArrivals = true

        Task {
            await withTaskGroup(of: (Int, String?).self) { group in
                for route in stop.routes {
                    group.addTask {
                        let arrival = try? await BusArrivalService.shared.getArrivalInfo(
                            stId: stop.id,
                            busRouteId: route.routeId
                        )
                        return (route.routeId, arrival)
                    }
                }

                for await (routeId, arrival) in group {
                    busArrivals[routeId] = arrival ?? "도착 정보 없음"
                }
            }

            isLoadingArrivals = false
        }
    }
}

#Preview {
    HomeView()
}
