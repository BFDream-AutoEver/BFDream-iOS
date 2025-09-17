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
            subtitle: "임산부 돌봄의 번거로움 없는 안전한 버스 배차의 탑승을\n도와드릴게요!"
        ),
        OnBoardingData(
            image: "Onboard2", 
            title: "부담없는 제로",
            subtitle: "탑승하려는 버스의 입석부 배차에 일반인들을 볼 수 있어요!\n이로 인해 탑승객들의 지연스러운 배차적 일정감\n가능합니다."
        ),
        OnBoardingData(
            image: "Onboard3",
            title: "쉽고 간편하게",
            subtitle: "GPS와 실시간 버스 데이터 기반으로\n주변 정류장의 탑승할 버스 도착 정보를 확인하고,\n일정한 줄임맞춤 해!"
        ),
        OnBoardingData(
            image: "Onboard4",
            title: "임산부들만 이용가능",
            subtitle: "임산부 신고 후 본 서비스를 이용하실 수 있습니다.\n현재 일반 승차 서비스는 서비스 준비중입니다."
        )
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<onboardingData.count, id: \.self) { index in
                    VStack(spacing: 40) {
                        Spacer()
                        
                        Image(onboardingData[index].image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 300)
                        
                        VStack(spacing: 16) {
                            titleView(for: index)
                                .multilineTextAlignment(.center)
                            
                            Text(onboardingData[index].subtitle)
                                .moveFont(.homeSubTitle)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color("MainPalette1") : Color.gray.opacity(0.3))
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
        .background(Color("PrimaryColor"))
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
            Text(createAttributedString(from: title, highlight: "임산부", color: Color("CircularBus")))
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
