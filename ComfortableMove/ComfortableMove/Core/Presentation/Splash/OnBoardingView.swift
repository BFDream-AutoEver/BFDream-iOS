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
                        if (index == onboardingData.count - 1) {
                            VStack(spacing: min(40, geometry.size.height * 0.05)) {
                                Spacer(minLength: 0)

                                Image(onboardingData[index].image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: min(200, geometry.size.height * 0.25))

                                titleView(for: index)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 22)
                                    .lineLimit(nil)
                                    .minimumScaleFactor(0.7)
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack(spacing: min(40, geometry.size.width * 0.1)) {
                                    // 위치 권한
                                    VStack(spacing: 8) {
                                        Image("distance")
                                            .resizable()
                                            .frame(width: 48, height: 48)
                                            .foregroundColor(.white)
                                            .padding(8)

                                        Text("위치")
                                            .moveFont(.homeSubTitle)
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                            .minimumScaleFactor(0.8)

                                        Text("현재 버스정류장 및\n탑승할 버스 안내")
                                            .moveFont(.caption)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(nil)
                                            .minimumScaleFactor(0.7)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    // 블루투스 권한
                                    VStack(spacing: 8) {
                                        Image("bluetooth")
                                            .resizable()
                                            .frame(width: 48, height: 48)
                                            .foregroundColor(.white)
                                            .padding(8)

                                        Text("블루투스")
                                            .moveFont(.homeSubTitle)
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                            .minimumScaleFactor(0.8)

                                        Text("버스 내부 배려석 알림\n기기 통신")
                                            .moveFont(.caption)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(nil)
                                            .minimumScaleFactor(0.7)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(.horizontal, min(40, geometry.size.width * 0.1))

                                Spacer(minLength: 0)
                            }
                            .tag(index)
                        } else {
                            VStack(spacing: min(40, geometry.size.height * 0.05)) {
                                Spacer(minLength: 0)

                                Image(onboardingData[index].image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: min(300, geometry.size.height * 0.4))

                                VStack(spacing: min(16, geometry.size.height * 0.02)) {
                                    titleView(for: index)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                        .minimumScaleFactor(0.7)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Text(onboardingData[index].subtitle)
                                        .moveFont(.homeSubTitle)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                        .minimumScaleFactor(0.7)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal, 22)

                                Spacer(minLength: 0)
                            }
                            .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color("MainPalette1") : Color("OnboardingGray"))
                                .frame(width: 8, height: 8)
                        }
                    }

                    if currentPage == onboardingData.count - 1 {
                        Button(action: {
                            onOnBoardingCompleted()
                        }) {
                            Text("시작하기")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 160, height: 60)
                                .background(Color("MainPalette1"))
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("다음")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 160, height: 60)
                                .background(Color("MainPalette1"))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
            .background(Color("BFPrimaryColor"))
        }
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
