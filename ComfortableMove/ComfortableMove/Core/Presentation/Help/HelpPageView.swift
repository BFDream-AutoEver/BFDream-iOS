//
//  HelpPageView.swift
//  ComfortableMove
//
//  Created by 박성근 on 10/16/25.
//

import SwiftUI

struct HelpPageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    private var helpImages: [String] {
        if UIApplication.isMinimumSizeDevice {
            return ["RatioFixHelpImage1", "RatioFixHelpImage2"]
        } else {
            return ["HelpImage1", "HelpImage2"]
        }
    }
    
    private var backButton: some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
        }
        .accessibleLabel(A11yLabels.back, traits: .isButton)
    }
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<helpImages.count, id: \.self) { index in
                Image(helpImages[index])
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .tag(index)
                    .accessibleLabel(A11yLabels.helpPageDescription(for: index), hint: A11yLabels.helpImageHint, traits: .isImage)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Color("BFPrimaryColor")
                Color.black.opacity(0.6)
            }
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("도움말")
                    .moveFont(.homeMediumTitle)
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .toolbarBackground(Color("BFPrimaryColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        HelpPageView()
    }
}
