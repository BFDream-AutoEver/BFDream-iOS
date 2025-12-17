//
//  HelpPageView.swift
//  ComfortableMove
//
//  Created by 박성근 on 10/16/25.
//

import SwiftUI

struct HelpPageView: View {
    @Environment(\.dismiss) private var dismiss

    private var backButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Image("HelpImage")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BFPrimaryColor"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("도움말")
                    .moveFont(.homeMediumTitle)
                    .foregroundColor(.white)
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
