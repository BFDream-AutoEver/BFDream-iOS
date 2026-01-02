//
//  InfoView.swift
//  ComfortableMove
//
//  Created by 박성근 on 10/16/25.
//

import SwiftUI

struct InfoView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var backButton : some View {  // <-- 👀 커스텀 버튼
        Button{
            HapticManager.shared.impact(style: .light) // 햅틱 추가
            self.presentationMode.wrappedValue.dismiss()
        } label: {
            HStack {
                Image(systemName: "chevron.left") // 화살표 Image
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color.white)
            }
        }
        .accessibleLabel(A11yLabels.back, traits: .isButton) // 접근성 추가
    }
    
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
                .accessibleLabel(A11yLabels.appInfoImage, traits: .isImage) // 접근성 추가
            
            // 하단 리스트 영역
            VStack(spacing: 0) {
                // 배려석 알림음 설정
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("배려석 알림음 on/off")
                            .moveFont(.homeSubTitle)
                            .foregroundColor(.mainPalette2)

                        Text("알림음을 꺼도 불빛과 전광판 알림은 유지됩니다.")
                            .moveFont(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .accessibleGroup(combine: true) // 텍스트 그룹화

                    Spacer()

                    Toggle("", isOn: $isSoundEnabled)
                        .labelsHidden()
                        .onChange(of: isSoundEnabled) { _, _ in
                            HapticManager.shared.impact(style: .light) // 토글 시 햅틱
                        }
                        .accessibleLabel(A11yLabels.soundToggle, hint: A11yLabels.soundToggleHint, value: A11yLabels.soundToggleValue(isSoundEnabled)) // 접근성 추가
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)

                Divider()
                    .padding(.leading, 20)

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
                .accessibleGroup(combine: true, label: "현재 버전", value: appVersion) // 접근성 추가
                
                Divider()
                    .padding(.leading, 20)
                
                // 앱 문의
                Button(action: {
                    HapticManager.shared.impact(style: .light) // 햅틱 추가
                    if let url = URL(string: "https://forms.gle/rnSD44sUEuy1nLaH6") {
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
                .accessibleLabel(A11yLabels.appInquiry, hint: A11yLabels.appInquiryHint, traits: [.isButton, .isLink]) // 접근성 추가
                
                Divider()
                    .padding(.leading, 20)
                
                // 개인정보 처리 방침 및 이용약관
                Button(action: {
                    HapticManager.shared.impact(style: .light) // 햅틱 추가
                    if let url = URL(string: "https://important-hisser-903.notion.site/10-22-ver-29a65f12c44480b6b591e726c5c80f89?source=copy_link") {
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
                .accessibleLabel(A11yLabels.privacyPolicy, hint: A11yLabels.privacyPolicyHint, traits: [.isButton, .isLink]) // 접근성 추가
            }
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color("BFPrimaryColor"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("앱 정보")
                    .moveFont(.homeMediumTitle)
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader) // 헤더 특성 추가
            }
        }
        .toolbarBackground(Color("BFPrimaryColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    InfoView()
}