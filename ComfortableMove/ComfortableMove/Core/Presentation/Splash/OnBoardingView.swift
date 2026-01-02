//
//  OnBoardingView.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/17/25.
//

import SwiftUI

struct OnBoardingData {
    let image: String
    let title: String
    let subtitle: String
}

struct OnBoardingView: View {
    let onOnBoardingCompleted: () -> Void
    @State private var currentPage = 0
    
    private let onboardingData = [
        OnBoardingData(
            image: "Onboard1",
            title: "안녕하세요 :)\n맘편한 이동입니다",
            subtitle: "임산부 분들의 편안하고 안전한 버스 배려석 탑승을 도와드릴게요!"
        ),
        OnBoardingData(
            image: "Onboard2", 
            title: "부담감 제로",
            subtitle: "탑승하려는 버스의 임산부 배려석에 알림을 줄 수 있어요! 이로 인해 탑승객들의 자연스러운 배려석 양보가 가능합니다."
        ),
        OnBoardingData(
            image: "Onboard3",
            title: "쉽고 간편하게",
            subtitle: "GPS와 실시간 버스 데이터 기반으로 주변 정류장의 탑승할 버스 도착 정보를 확인하고, 알림만 울리면 끝!"
        ),
        OnBoardingData(
            image: "Onboard4",
            title: "임산부들만 이용가능",
            subtitle: "임산부 신고 후, 해당 서비스를 이용하실 수 있습니다. 임산부 신고는 e보건소 혹은 직접 방문, 아이마중 어플 등을 통해 가능합니다."
        ),
        OnBoardingData(
            image: "InfoImage",
            title: "맘편한 이동을 위한 필수 접근권한 안내",
            subtitle: ""
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        ScrollView { // 스크롤 뷰 추가: 글자가 커져서 화면을 넘어가도 볼 수 있게 함
                            VStack(spacing: 20) {
                                Spacer(minLength: 20)
                                
                                Image(onboardingData[index].image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: min(240, geometry.size.height * 0.3)) // 이미지 크기 유연하게 조정
                                    .accessibleLabel(A11yLabels.onboardingImage(for: index), traits: .isImage)

                                if index == onboardingData.count - 1 {
                                    // 권한 안내 페이지
                                    titleView(for: index)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 22)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .accessibilityAddTraits(.isHeader)

                                    HStack(spacing: 20) {
                                        // 위치 권한
                                        permissionItem(
                                            icon: "distance",
                                            title: "위치",
                                            desc: "현재 버스정류장 및\n탑승할 버스 안내",
                                            label: "위치 권한",
                                            hint: "현재 버스정류장 및 탑승할 버스를 안내하기 위해 필요합니다"
                                        )

                                        // 블루투스 권한
                                        permissionItem(
                                            icon: "bluetooth",
                                            title: "블루투스",
                                            desc: "버스 내부 배려석 알림\n기기 통신",
                                            label: "블루투스 권한",
                                            hint: "버스 내부 배려석 알림 기기와 통신하기 위해 필요합니다"
                                        )
                                    }
                                    .padding(.horizontal, 20)
                                } else {
                                    // 일반 온보딩 페이지
                                    VStack(spacing: 16) {
                                        titleView(for: index)
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .accessibilityAddTraits(.isHeader)

                                        Text(onboardingData[index].subtitle)
                                            .moveFont(.homeSubTitle)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true) // 세로로 늘어나도록 허용
                                    }
                                    .padding(.horizontal, 22)
                                    .accessibleGroup(combine: true)
                                }
                                
                                Spacer(minLength: 40) // 하단 버튼과의 간격 확보
                            }
                            .frame(minHeight: geometry.size.height - 100) // 탭뷰 내부 높이 확보
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, newValue in
                    let announcement = "\(newValue + 1)페이지"
                    UIAccessibility.post(notification: .pageScrolled, argument: announcement)
                }

                // 하단 인디케이터 및 버튼 영역 (고정)
                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingData.count, id: \.self) {
                            index in
                            Circle()
                                .fill(currentPage == index ? Color("MainPalette1") : Color("OnboardingGray"))
                                .frame(width: 8, height: 8)
                                .accessibleLabel(
                                    A11yLabels.pageIndicator(index, isCurrent: currentPage == index),
                                    value: A11yLabels.pageIndicatorValue(isCurrent: currentPage == index)
                                )
                        }
                    }
                    .accessibilityElement(children: .ignore)

                    Button(action: {
                        HapticManager.shared.impact(style: .light)
                        if currentPage == onboardingData.count - 1 {
                            onOnBoardingCompleted()
                        } else {
                            withAnimation {
                                currentPage += 1
                                let announcement = "페이지 이동. \(currentPage + 1)페이지"
                                UIAccessibility.post(notification: .pageScrolled, argument: announcement)
                            }
                        }
                    }) {
                        Text(currentPage == onboardingData.count - 1 ? "시작하기" : "다음")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 60) // 최소 높이 설정 (글자가 커지면 버튼도 커짐)
                            .background(Color("MainPalette1"))
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                    }
                    .accessibleLabel(currentPage == onboardingData.count - 1 ? "시작하기" : "다음 페이지", traits: .isButton)
                }
                .padding(.bottom, 20)
                .background(Color("BFPrimaryColor")) // 버튼 영역 배경색 (스크롤 위로 덮일 때 자연스럽게)
            }
            .background(Color("BFPrimaryColor"))
        }
    }
    
    // 권한 아이템 뷰 추출 (코드 중복 제거 및 안전성 확보)
    private func permissionItem(icon: String, title: String, desc: String, label: String, hint: String) -> some View {
        VStack(spacing: 8) {
            Image(icon)
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.white)
                .padding(8)
                .decorativeImage()

            Text(title)
                .moveFont(.homeSubTitle)
                .foregroundColor(.white)
                .fontWeight(.bold)
                .minimumScaleFactor(0.8)

            Text(desc)
                .moveFont(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibleGroup(combine: true, label: label, hint: hint)
    }
    
    @ViewBuilder
    private func titleView(for index: Int) -> some View {
        let title = onboardingData[index].title
        
        switch index {
        case 0:
            Text(createAttributedString(from: title, highlight: "맘편한 이동", color: Color("MainPalette1")))
                .moveFont(.homeTitle)
        case 1:
            Text(createAttributedString(from: title, highlight: "제로", color: Color("SecondaryPalette4")))
                .moveFont(.homeTitle)
        case 2:
            Text(createAttributedString(from: title, highlight: "간편하게", color: Color("SecondaryPalette3")))
                .moveFont(.homeTitle)
        case 3:
            Text(createAttributedString(from: title, highlight: "임산부", color: Color("Onboarding4")))
                .moveFont(.homeTitle)
        case 4:
            Text(createAttributedString(from: title, highlight: "맘편한 이동", color: Color("MainPalette1")))
                .moveFont(.homeTitle)
        default:
            Text(title)
                .moveFont(.splashTitle)
                .foregroundColor(.white)
        }
    }
    
    private func createAttributedString(from text: String, highlight: String, color: Color) -> AttributedString {
        var attributedString = AttributedString(text)
        attributedString.foregroundColor = .white
        
        if let range = attributedString.range(of: highlight) {
            attributedString[range].foregroundColor = color
        }
        
        return attributedString
    }
}

#Preview {
    OnBoardingView(onOnBoardingCompleted: {}) 
}
