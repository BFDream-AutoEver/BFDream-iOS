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
    
    // Dynamic Type을 위한 기준 스타일 (relativeTo)
    var textStyle: Font.TextStyle {
        switch self {
        case .homeTitle, .splashTitle: return .largeTitle
        case .homeMediumTitle, .splashSubTitle: return .title
        case .homeSubTitle, .buttonText: return .body
        case .caption: return .caption
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
        // Font.custom(_:size:relativeTo:)를 사용하여 Dynamic Type 지원
        // relativeTo 파라미터가 있어야 시스템 폰트 크기 설정에 맞춰 함께 커짐
        return self.font(.custom(type.fontName.rawValue, size: type.fontSize, relativeTo: type.textStyle))
    }
}