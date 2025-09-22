//
//  HabitPilotApp.swift
//  HabitPilot
//
//  Created by Developer on 7/2/25.
//

import SwiftUI
import UserNotifications
import StoreKit

/// Main application entry point for HabitPilot
/// Handles app lifecycle, state management, and dependency injection
@main
struct HabitPilotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var purchaseService = PurchaseService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var animationService = AnimationHelper.shared
    @StateObject private var habitStore = HabitStore()
    @StateObject private var goalStore = GoalStore()
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var taskStore = TaskStore()
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var challengeManager = ChallengeManager.shared
    @StateObject private var dataCoordinator: DataCoordinator
    @StateObject private var friendManager = FriendManager.shared
    @StateObject private var aiViewModel = AIViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    
    @State private var showSplash = true

    init() {
        // Initialize stores properly
        let habitStore = HabitStore()
        let goalStore = GoalStore()
        let taskStore = TaskStore()
        
        _habitStore = StateObject(wrappedValue: habitStore)
        _goalStore = StateObject(wrappedValue: goalStore)
        _taskStore = StateObject(wrappedValue: taskStore)
        
        _dataCoordinator = StateObject(wrappedValue: DataCoordinator(habitStore: habitStore, goalStore: goalStore, taskStore: taskStore))
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Request notification permissions when app launches
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    // Notification permission granted
                } else if let error = error {
                    // Handle notification permission error
                    _ = error
                } else {
                    // Notification permission denied
                }
            }
        }
        
        // Check notification status
        NotificationManager.shared.checkNotificationStatus()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    LaunchView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                } else {
                    SwiftUI.Group {
                        switch authManager.authState {
                        case .notAuthenticated, .authenticating, .error:
                            LoginView()
                        case .authenticated:
                            ContentView()
                                .onAppear {
                                    Task {
                                        await dataCoordinator.syncAllData()
                                    }
                                }
                        }
                    }
                    .environmentObject(purchaseService)
                    .environmentObject(themeManager)
                    .environmentObject(animationService)
                    .environmentObject(habitStore)
                    .environmentObject(goalStore)
                    .environmentObject(achievementManager)
                    .environmentObject(taskStore)
                    .environmentObject(authManager)
                    .environmentObject(challengeManager)
                    .environmentObject(friendManager)
                    .environmentObject(aiViewModel)
                    .environmentObject(notificationManager)
                    .environmentObject(settingsManager)
                    .withTheme(themeManager)
                    .onAppear {
                        // Set up StoreManager with the main stores
                        StoreManager.shared.setStores(
                            habitStore: habitStore,
                            taskStore: taskStore,
                            goalStore: goalStore
                        )
                        
                        // Load products when app starts
                        Task {
                            await purchaseManager.loadProducts()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set custom navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Set tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        return true
    }
}
