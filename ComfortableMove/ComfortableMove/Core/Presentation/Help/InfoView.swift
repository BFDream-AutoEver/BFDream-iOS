//
//  InfoView.swift
//  ComfortableMove
//
//  Created by 박성근 on 10/16/25.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            // 상단 이미지 영역
            Image("InfoImage")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 170)
                .padding(.bottom, 100)

            // 하단 리스트 영역
            VStack(spacing: 0) {
                // 버전 정보
                HStack {
                    Text("버전")
                        .moveFont(.homeSubTitle)
                        .foregroundColor(.mainPalette2)
                    Spacer()
                    Text("v \(appVersion)")
                        .moveFont(.homeSubTitle)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)

                Divider()
                    .padding(.leading, 20)

                // 앱 문의
                Button(action: {
                    if let url = URL(string: "https://github.com/ParkSeongGeun") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("앱 문의")
                            .moveFont(.homeSubTitle)
                            .foregroundColor(.mainPalette2)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .moveFont(.homeSubTitle)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                }

                Divider()
                    .padding(.leading, 20)

                // 개인정보 처리 방침 및 이용약관
                Button(action: {
                    if let url = URL(string: "https://github.com/ParkSeongGeun") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("개인정보 처리 방침 및 이용약관")
                            .moveFont(.homeSubTitle)
                            .foregroundColor(.mainPalette2)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .moveFont(.homeSubTitle)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                }
            }
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color("BFPrimaryColor"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .navigationTitle("앱정보")
        .toolbarBackground(Color("BFPrimaryColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    InfoView()
}
