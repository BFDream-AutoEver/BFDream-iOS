//
//  HelpPageView.swift
//  ComfortableMove
//
//  Created by 박성근 on 10/16/25.
//

import SwiftUI

struct HelpPageView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 0) {
                Image("HelpImage")
                    .resizable()
                    .interpolation(.high)
                    .ignoresSafeArea()
            }

            // 상단 헤더 영역
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        HelpPageView(isPresented: .constant(true))
    }
}
