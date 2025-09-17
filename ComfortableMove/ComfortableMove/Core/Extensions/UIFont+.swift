//
//  UIFont+.swift
//  ComfortableMove
//
//  Created by 박성근 on 9/17/25.
//

import SwiftUI

enum FontType {
    case homeTitle
    case homeMediumTitle
    case homeSubTitle
    case caption
    case splashTitle
    case splashSubTitle
    case buttonText
    
    var fontName: PretendardWeight {
        switch self {
        case .homeTitle: return .extraBold
        case .homeMediumTitle, .homeSubTitle, .buttonText: return .bold
        case .caption, .splashTitle, .splashSubTitle: return .regular
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .homeTitle: return 36
        case .homeMediumTitle: return 24
        case .homeSubTitle: return 16
        case .caption: return 12
        case .splashTitle: return 64
        case .splashSubTitle: return 24
        case .buttonText: return 20
        }
    }
}

enum PretendardWeight: String {
    case bold = "Pretendard-Bold"
    case extraBold = "Pretendard-ExtraBold"
    case regular = "Pretendard-Regular"
}

extension View {
    func moveFont(_ type: FontType) -> some View {
        let font = UIFont(name: type.fontName.rawValue, size: type.fontSize) ?? UIFont.systemFont(ofSize: type.fontSize)
        
        return self
    }
}
