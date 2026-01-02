//
//  HapticManager.swift
//  ComfortableMove
//
//  Created by 박성근 on 1/2/26.
//

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// 성공, 에러, 경고 등의 알림 햅틱
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// 버튼 클릭 등 일반적인 충격 햅틱
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
