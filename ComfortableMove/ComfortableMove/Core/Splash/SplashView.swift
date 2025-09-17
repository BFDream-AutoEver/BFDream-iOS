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
            
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
            
            VStack(spacing: 8) {
                Text("맘편한이동")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("예비 엄마의 마음 편한 이동")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("PrimaryColor"))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onSplashCompleted()
            }
        }
    }
}

#Preview {
    SplashView(onSplashCompleted: {})
}
