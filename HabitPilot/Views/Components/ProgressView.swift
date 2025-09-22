import SwiftUI

struct ProgressUpdateView: View {
    let challenge: Challenge
    let challengeManager: ChallengeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var updateValue = ""
    @State private var selectedUpdateType: UpdateType = .increment
    @State private var isUpdating = false
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    enum UpdateType: String, CaseIterable {
        case increment = "Add Progress"
        case setValue = "Set Total"
        
        var icon: String {
            switch self {
            case .increment: return "plus.circle"
            case .setValue: return "equal.circle"
            }
        }
        
        var description: String {
            switch self {
            case .increment: return "Add to current progress"
            case .setValue: return "Set total progress value"
            }
        }
    }
    
    private var userParticipant: LegacyChallengeParticipant? {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return nil }
        return challenge.participants.first { $0.userId == currentUserId }
    }
    
    private var currentProgress: Int {
        userParticipant?.currentValue ?? 0
    }
    
    private var targetValue: Int {
        challenge.targetValue
    }
    
    private var updateValueInt: Int {
        Int(updateValue) ?? 0
    }
    
    private var previewProgress: Int {
        switch selectedUpdateType {
        case .increment:
            return min(currentProgress + updateValueInt, targetValue)
        case .setValue:
            return min(updateValueInt, targetValue)
        }
    }
    
    private var previewPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(previewProgress) / Double(targetValue), 1.0)
    }
    
    private var canSubmit: Bool {
        !updateValue.isEmpty && updateValueInt > 0 && !isUpdating
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: challenge.category.color).opacity(0.1),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Current Progress
                        currentProgressSection
                        
                        // Update Type Selection
                        updateTypeSection
                        
                        // Input Section
                        inputSection
                        
                        // Preview Section
                        previewSection
                        
                        // Quick Actions
                        quickActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle("Update Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        hapticFeedback.impactOccurred()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        hapticFeedback.impactOccurred()
                        updateProgress()
                    }
                    .foregroundColor(canSubmit ? Color(hex: challenge.category.color) : .secondary)
                    .disabled(!canSubmit)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Challenge icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: challenge.category.color),
                                Color(hex: challenge.category.color).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: challenge.challengeType.defaultIcon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Title
            VStack(spacing: 4) {
                Text(challenge.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Update your progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Current Progress Section
    private var currentProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Progress")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(currentProgress)/\(targetValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: challenge.category.color))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: challenge.category.color),
                                    Color(hex: challenge.category.color).opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * (Double(currentProgress) / Double(targetValue)),
                            height: 12
                        )
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(Int((Double(currentProgress) / Double(targetValue)) * 100))% Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if currentProgress >= targetValue {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                        Text("Completed!")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Update Type Section
    private var updateTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Update Method")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(UpdateType.allCases, id: \.self) { type in
                    UpdateTypeCard(
                        type: type,
                        isSelected: selectedUpdateType == type
                    ) {
                        hapticFeedback.impactOccurred()
                        selectedUpdateType = type
                        updateValue = "" // Clear input when switching types
                    }
                }
            }
        }
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter Value")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                TextField("0", text: $updateValue)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                !updateValue.isEmpty ? Color(hex: challenge.category.color).opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
                
                Text(selectedUpdateType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Preview")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("New Progress:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(previewProgress)/\(targetValue)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: challenge.category.color))
                }
                
                // Preview progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: challenge.category.color))
                            .frame(
                                width: geometry.size.width * previewPercentage,
                                height: 8
                            )
                            .animation(.easeInOut(duration: 0.3), value: previewPercentage)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(Int(previewPercentage * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if previewProgress >= targetValue {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text("Challenge Complete!")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: challenge.category.color).opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: challenge.category.color).opacity(0.2), lineWidth: 1)
        )
        .opacity(!updateValue.isEmpty && updateValueInt > 0 ? 1.0 : 0.5)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(value: 1, unit: challenge.challengeType.unit) {
                    hapticFeedback.impactOccurred()
                    updateValue = "1"
                }
                
                QuickActionButton(value: 5, unit: challenge.challengeType.unit) {
                    hapticFeedback.impactOccurred()
                    updateValue = "5"
                }
                
                QuickActionButton(value: 10, unit: challenge.challengeType.unit) {
                    hapticFeedback.impactOccurred()
                    updateValue = "10"
                }
            }
        }
    }
    
    // MARK: - Update Progress
    private func updateProgress() {
        guard canSubmit else { return }
        
        isUpdating = true
        
        Task {
            let success: Bool
            
            switch selectedUpdateType {
            case .increment:
                success = await challengeManager.updateProgress(challenge, increment: updateValueInt)
            case .setValue:
                success = await challengeManager.updateProgress(challenge, newValue: updateValueInt)
            }
            
            await MainActor.run {
                isUpdating = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Update Type Card
struct UpdateTypeCard: View {
    let type: ProgressUpdateView.UpdateType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                isSelected
                ? LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color(.systemBackground), Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 6 : 2, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let value: Int
    let unit: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("+\(value)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 