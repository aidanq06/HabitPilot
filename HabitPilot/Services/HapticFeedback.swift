import UIKit

class HapticFeedback {
    static let shared = HapticFeedback()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func heavyImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    func softImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
    }
    
    func rigidImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    func successNotification() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    func warningNotification() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    func errorNotification() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    func selectionChanged() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Custom Haptic Patterns
    
    func habitCompleted() {
        // Light impact followed by success notification
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.successNotification()
        }
    }
    
    func streakMilestone() {
        // Medium impact followed by success notification
        mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.successNotification()
        }
    }
    
    func achievementUnlocked() {
        // Heavy impact followed by success notification
        heavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.successNotification()
        }
    }
    
    func buttonPress() {
        lightImpact()
    }
    
    func cardTap() {
        softImpact()
    }
    
    func errorOccurred() {
        errorNotification()
    }
    
    func warningOccurred() {
        warningNotification()
    }
}

// MARK: - SwiftUI Extensions

import SwiftUI

extension View {
    func hapticFeedback(_ feedback: @escaping () -> Void) -> some View {
        self.onTapGesture {
            feedback()
        }
    }
    
    func habitCompletionHaptic() -> some View {
        self.onTapGesture {
            HapticFeedback.shared.habitCompleted()
        }
    }
    
    func buttonPressHaptic() -> some View {
        self.onTapGesture {
            HapticFeedback.shared.buttonPress()
        }
    }
    
    func cardTapHaptic() -> some View {
        self.onTapGesture {
            HapticFeedback.shared.cardTap()
        }
    }
} 
