//
//  BusNumber.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/17/25.
//

import SwiftUI

struct BusNumberRow: View {
    let number: String
    let isSelected: Bool
    let color: Color
    
    var body: some View {
        HStack {
            Text(number)
                .moveFont(.homeMediumTitle)
                .foregroundColor(color)
                .fontWeight(.bold)
            
            Spacer()
            
            Circle()
                .fill(isSelected ? color : Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isSelected ? 1 : 0)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(8)
    }
}
