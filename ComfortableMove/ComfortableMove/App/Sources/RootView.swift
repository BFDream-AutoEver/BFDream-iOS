//
//  RootView.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/17/25.
//

import SwiftUI

struct RootView: View {
    @State private var showSplash = true
    
    var body: some View {
        Group {
            if showSplash {
                SplashView();
            } else {
                HomeView();
            }
        }
    }
}
