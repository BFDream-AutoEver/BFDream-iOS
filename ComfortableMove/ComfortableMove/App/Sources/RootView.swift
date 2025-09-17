//
//  RootView.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/17/25.
//

import SwiftUI

struct RootView: View {
    @State private var showSplash = true
    @State private var showOnBoarding = false
    @State private var isFirstLaunch = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") == false
    
    var body: some View {
        Group {
            if showSplash {
                SplashView(onSplashCompleted: {
                    showSplash = false
                    if isFirstLaunch {
                        showOnBoarding = true
                    }
                })
            } else if showOnBoarding && isFirstLaunch {
                OnBoardingView(onOnBoardingCompleted: {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    showOnBoarding = false
                    isFirstLaunch = false
                })
            } else {
                HomeView()
            }
        }
    }
}
