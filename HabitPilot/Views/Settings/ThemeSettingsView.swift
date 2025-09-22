import SwiftUI

struct ThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var currentTheme: ThemeManager.ThemeMode = .system
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Appearance")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.infoBlue)
                    }
                }
        }
        .withTheme(themeManager)
        .id(themeManager.currentThemeMode) // Force view refresh when theme changes
        .onAppear {
            currentTheme = themeManager.currentThemeMode
        }
        .onChange(of: themeManager.currentThemeMode) { _, newTheme in
            currentTheme = newTheme
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            Color.secondaryBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    themeOptionsSection
                    previewSection
                    infoSection
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "paintbrush.fill")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.infoBlue)
                .padding(.top, 20)
            
            Text("Appearance")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            Text("Choose how HabitPilot looks on your device")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var themeOptionsSection: some View {
        VStack(spacing: 16) {
            ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { theme in
                ThemeOptionCard(
                    theme: theme,
                    isSelected: currentTheme == theme
                ) {
                    // Immediately apply theme change with haptic feedback
                    HapticFeedback.shared.lightImpact()
                    
                    // Update theme immediately
                    themeManager.currentThemeMode = theme
                    
                    // Force immediate UI update
                    DispatchQueue.main.async {
                        themeManager.objectWillChange.send()
                    }
                    
                    // Also save to backend
                    Task {
                        await settingsManager.updateTheme(String(theme.rawValue))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var previewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Preview")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Spacer()
            }
            
            ThemePreviewCard(currentTheme: currentTheme)
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var infoSection: some View {
        VStack(spacing: 12) {
            infoRow(
                icon: "info.circle.fill",
                iconColor: .infoBlue,
                text: "System theme automatically follows your device settings"
            )
            
            infoRow(
                icon: "moon.stars.fill",
                iconColor: .purple,
                text: "Dark mode reduces eye strain in low-light environments"
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: .cardShadow, radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func infoRow(icon: String, iconColor: Color, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondaryText)
            
            Spacer()
        }
    }
}

struct ThemeOptionCard: View {
    let theme: ThemeManager.ThemeMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(themeColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: theme.icon)
                        .font(.title2)
                        .foregroundColor(themeColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryText)
                    
                    Text(themeDescription)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.successGreen)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.successGreen : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .cardShadow, radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var themeColor: Color {
        switch theme {
        case .system:
            return .infoBlue
        case .light:
            return .warningOrange
        case .dark:
            return .purple
        }
    }
    
    private var themeDescription: String {
        switch theme {
        case .system:
            return "Follows your device settings"
        case .light:
            return "Always use light appearance"
        case .dark:
            return "Always use dark appearance"
        }
    }
}

struct ThemePreviewCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currentTheme: ThemeManager.ThemeMode
    
    var body: some View {
        VStack(spacing: 12) {
            // Preview header
            HStack {
                Text("Sample Habit")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("75%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.successGreen)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondaryBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.successGreen)
                        .frame(width: geometry.size.width * 0.75, height: 8)
                        .animation(.easeInOut(duration: 1.0), value: currentTheme)
                }
            }
            .frame(height: 8)
            
            // Preview stats
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.warningOrange)
                        .font(.caption)
                    
                    Text("5 day streak")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.infoBlue)
                        .font(.caption)
                    
                    Text("Reminder set")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: .cardShadow, radius: 6, x: 0, y: 2)
        )
    }
}

#Preview {
    ThemeSettingsView()
        .environmentObject(ThemeManager.shared)
} 