import SwiftUI

struct StreakLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var friendManager: FriendManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if friendManager.acceptedFriends.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Friends to Compare")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Add friends to see who has the highest streak")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Top 3 Podium
                            HStack(spacing: 20) {
                                // 2nd Place
                                if friendManager.acceptedFriends.count >= 2 {
                                    VStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Text("2")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.gray)
                                            )
                                        
                                        Text(friendManager.acceptedFriends[1].friendUsername)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        
                                        Text("\(Int.random(in: 15...25)) days")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // 1st Place
                                VStack {
                                    Circle()
                                        .fill(Color.yellow.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            VStack {
                                                Text("👑")
                                                    .font(.title)
                                                Text("1")
                                                    .font(.title)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.yellow)
                                            }
                                        )
                                    
                                    Text(friendManager.acceptedFriends[0].friendUsername)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("\(Int.random(in: 30...50)) days")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // 3rd Place
                                if friendManager.acceptedFriends.count >= 3 {
                                    VStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Text("3")
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.orange)
                                            )
                                        
                                        Text(friendManager.acceptedFriends[2].friendUsername)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        
                                        Text("\(Int.random(in: 5...15)) days")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.top, 20)
                            
                            // Full Leaderboard
                            VStack(spacing: 8) {
                                Text("Full Leaderboard")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                ForEach(Array(friendManager.acceptedFriends.enumerated()), id: \.element.id) { index, friend in
                                    LeaderboardRow(
                                        rank: index + 1,
                                        username: friend.friendUsername,
                                        streak: Int.random(in: 1...50),
                                        isCurrentUser: false
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Your Stats Section
                            VStack(spacing: 12) {
                                Text("Your Stats")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 8) {
                                    StatRow(title: "Current Streak", value: "7", icon: "flame.fill", color: .orange)
                                    StatRow(title: "Best Streak", value: "21", icon: "trophy.fill", color: .yellow)
                                    StatRow(title: "Total Completions", value: "156", icon: "checkmark.circle.fill", color: .green)
                                    StatRow(title: "Average Streak", value: "12", icon: "chart.line.uptrend.xyaxis", color: .blue)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Streak Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - LeaderboardRow Component
struct LeaderboardRow: View {
    let rank: Int
    let username: String
    let streak: Int
    let isCurrentUser: Bool
    @State private var showingProfile = false
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }
    
    private var backgroundFill: Color {
        if isCurrentUser {
            return Color.blue.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }
    
    var body: some View {
        Button(action: {
            showingProfile = true
        }) {
            HStack(spacing: 12) {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rankColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Text("#\(rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(rankColor)
                }
                
                // User avatar
                ProfileImageView(
                    username: username,
                    size: 40
                )
                
                // User info
                VStack(alignment: .leading, spacing: 2) {
                    Text(username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(streak) day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Streak flames
                HStack(spacing: 2) {
                    ForEach(0..<min(streak, 3), id: \.self) { _ in
                        Text("🔥")
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundFill)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingProfile) {
            // Create a User object for the profile view
            let user = User(
                id: "user_\(username)", // Generate a placeholder ID
                username: username,
                email: nil,
                createdAt: Date(), // We don't have this info
                lastLoginAt: Date(),
                isAppleUser: false
            )
            UserProfileDetailView(user: user)
        }
    }
}

// MARK: - StatRow Component
struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
    }
} 