//
//  ContentView.swift
//  HabitPilot
//
//  Created by Developer on 7/2/25.
//

import SwiftUI

/// Main view container for the HabitPilot application
/// Manages tab navigation and coordinates between different app sections
struct MainView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var achievementManager: AchievementManager
    @StateObject private var goalStore = GoalStore()
    @StateObject private var taskStore = TaskStore()
    @State private var selectedTab: Tab = .habits
    @State private var showingUpgrade = false
    
    enum Tab: Int, CaseIterable {
        case habits = 0
        case tasks = 1
        case ai = 2
        case goals = 3
        case social = 4
        
        var title: String {
            switch self {
            case .habits: return "Habits"
            case .tasks: return "Tasks"
            case .ai: return "AI"
            case .goals: return "Goals"
            case .social: return "Social"
            }
        }
        
        var icon: String {
            switch self {
            case .habits: return "list.bullet"
            case .tasks: return "checkmark.circle"
            case .ai: return "brain"
            case .goals: return "target"
            case .social: return "person.2"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HabitsTabView(habitStore: habitStore, purchaseService: purchaseService, achievementManager: achievementManager)
                .tabItem {
                    Image(systemName: Tab.habits.icon)
                    Text(Tab.habits.title)
                }
                .tag(Tab.habits)
            
            TasksTabView()
                .tabItem {
                    Image(systemName: Tab.tasks.icon)
                    Text(Tab.tasks.title)
                }
                .tag(Tab.tasks)
            
            AITabView()
                .tabItem {
                    Image(systemName: Tab.ai.icon)
                    Text(Tab.ai.title)
                }
                .tag(Tab.ai)
            
            GoalsView(goalStore: goalStore, habitStore: habitStore)
                .tabItem {
                    Image(systemName: Tab.goals.icon)
                    Text(Tab.goals.title)
                }
                .tag(Tab.goals)
            
            SocialView()
                .tabItem {
                    Image(systemName: Tab.social.icon)
                    Text(Tab.social.title)
                }
                .tag(Tab.social)
        }
        .onAppear {
            habitStore.goalStore = goalStore
        }
        .sheet(isPresented: $showingUpgrade) {
            UpgradeView(purchaseService: purchaseService, habitStore: habitStore)
        }
    }
}

struct HabitsTabView: View {
    @ObservedObject var habitStore: HabitStore
    @ObservedObject var purchaseService: PurchaseService
    @ObservedObject var achievementManager: AchievementManager
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    @State private var showingUpgrade = false
    
    var body: some View {
        NavigationView {
            VStack {
                if habitStore.habits.isEmpty {
                    VStack(spacing: 20) {
                        Text("No Habits Yet")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text("Start building positive routines")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button("Add Your First Habit") {
                            if habitStore.canAddMoreHabits {
                                showingAddHabit = true
                            } else {
                                showingUpgrade = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(habitStore.habits) { habit in
                            HabitRowView(
                                habit: habit,
                                onToggleCompletion: {
                                    habitStore.toggleHabitCompletion(habit)
                                    achievementManager.checkAchievements(for: habitStore)
                                },
                                onToggleEnabled: {
                                    habitStore.toggleHabitEnabled(habit)
                                },
                                onTap: {
                                    selectedHabit = habit
                                },
                                onDelete: {
                                    habitStore.deleteHabit(habit)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if habitStore.canAddMoreHabits {
                            showingAddHabit = true
                        } else {
                            showingUpgrade = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(habitStore: habitStore, purchaseService: purchaseService, achievementManager: achievementManager)
            }
            .sheet(item: $selectedHabit) { habit in
                NavigationView {
                    HabitDetailView(habitID: habit.id, habitStore: habitStore)
                }
            }
            .sheet(isPresented: $showingUpgrade) {
                UpgradeView(purchaseService: purchaseService, habitStore: habitStore)
            }
        }
    }
}

#Preview {
    ContentView()
}
