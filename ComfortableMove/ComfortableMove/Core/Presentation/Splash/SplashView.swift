//
//  SplashView.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/17/25.
//

import SwiftUI

struct SplashView: View {
    let onSplashCompleted: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("Splash")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 304, height: 168)
            
            Text("예비 엄마의 마음 편한 이동")
                .moveFont(.homeMediumTitle)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BFPrimaryColor"))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onSplashCompleted()
            }
        }
    }
}

#Preview {
    SplashView(onSplashCompleted: {})
}
