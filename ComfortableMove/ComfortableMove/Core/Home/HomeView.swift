//
//  HomeView.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/17/25.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedBus: String? = "721"
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더
            VStack(spacing: 0) {
                // 상태바 영역
                Rectangle()
                    .fill(Color("PrimaryColor"))
                    .frame(height: 44)
                
                // 네비게이션 헤더
                HStack {
                    Text("맘편한 이동")
                        .moveFont(.homeMediumTitle)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            // 도움말 액션
                        }) {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            // 설정 액션
                        }) {
                            Image(systemName: "gearshape")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color("PrimaryColor"))
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                // 중앙 버튼
                Button(action: {
                    // 버튼 액션
                }) {
                    ZStack {
                        Circle()
                            .fill(Color("PrimaryColor"))
                            .frame(width: 225, height: 225)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Image("buttonImage")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                    }
                }
                .padding(.top, 40)
                
                // 버튼 아래 텍스트
                Text("버스 선택 후, 여기를 눌러주세요!")
                    .moveFont(.caption)
                    .foregroundColor(.gray)
            }
            
            // List 형태 메인 컨텐츠
            List {
                // 첫 번째 칸 - 정류장 정보
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("한아름공원")
                            .moveFont(.homeSubTitle)
                            .foregroundColor(.black)
                        
                        Text("건대입구역사거리 건대병원 방면")
                            .moveFont(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // 새로고침 액션
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
                
                // 버스 번호들
                ForEach(["721", "147", "2222"], id: \.self) { busNumber in
                    HStack {
                        Text(busNumber)
                            .moveFont(.homeSubTitle)
                            .foregroundColor(busNumber == "2222" ? .green : .blue)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            selectedBus = busNumber
                        }) {
                            Circle()
                                .fill(selectedBus == busNumber ? (busNumber == "2222" ? Color.green : Color.blue) : Color.gray.opacity(0.3))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .opacity(selectedBus == busNumber ? 1 : 0)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .padding(.top, 30)
            
            Spacer()
        }
        .background(Color("SecondaryPalette2"))
        .ignoresSafeArea(.all, edges: .top)
    }
}

#Preview {
    HomeView()
}
