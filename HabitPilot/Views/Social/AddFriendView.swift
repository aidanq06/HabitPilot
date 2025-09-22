import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendManager = FriendManager.shared
    @State private var searchText = ""
    @State private var pendingRequests: Set<String> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingProfile = false
    @State private var selectedUser: User?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for users...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            // Debounce search requests
                            Task {
                                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                                if searchText == newValue { // Only search if text hasn't changed
                                    await friendManager.searchUsers(query: newValue)
                                }
                            }
                        }
                }
                .padding()
                
                // Search Results
                if friendManager.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                        .foregroundColor(.secondary)
                    Spacer()
                } else if searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("Search for friends")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Enter a username to find and add friends")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else if friendManager.searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No users found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Try searching with a different username")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List(friendManager.searchResults, id: \.id) { user in
                        Button(action: {
                            selectedUser = user
                            showingProfile = true
                        }) {
                            HStack {
                                // User Avatar
                                ProfileImageView(
                                    username: user.username,
                                    size: 40
                                )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.username)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("User since \(user.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Button logic
                                let isFriend = friendManager.friends.contains { ($0.friendUsername == user.username || $0.userId == user.id || $0.friendId == user.id) && $0.status == .accepted }
                                let sentRequest = friendManager.outgoingRequests.contains { $0.toUsername == user.username && $0.status == .pending }
                                let receivedRequest = friendManager.friendRequests.contains { $0.fromUsername == user.username && $0.status == .pending }
                                
                                if isFriend {
                                    Text("Friends")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.2))
                                        )
                                } else if sentRequest {
                                    Button(action: {
                                        toggleFriendRequest(for: user.username)
                                    }) {
                                        Text("Added")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.green)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.green, lineWidth: 1)
                                                    )
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else if receivedRequest {
                                    Text("Requested You")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.orange.opacity(0.15))
                                        )
                                } else {
                                    Button(action: {
                                        toggleFriendRequest(for: user.username)
                                    }) {
                                        Text("Add Friend")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.clear)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.blue, lineWidth: 1)
                                                    )
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Friend Request", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingProfile) {
                if let user = selectedUser {
                    UserProfileDetailView(user: user)
                }
            }
            .onAppear {
                // Sync with API when view appears to ensure we have latest data
                Task {
                    await friendManager.syncWithAPI()
                }
            }
        }
    }
    
    private func toggleFriendRequest(for username: String) {
        if pendingRequests.contains(username) {
            // Cancel friend request
            Task {
                let success = await friendManager.cancelFriendRequest(to: username)
                await MainActor.run {
                    if success {
                        pendingRequests.remove(username)
                        alertMessage = "Friend request to \(username) cancelled"
                        showingAlert = true
                    } else {
                        alertMessage = friendManager.errorMessage ?? "Failed to cancel friend request"
                        showingAlert = true
                    }
                }
            }
        } else {
            // Send friend request
            Task {
                let success = await friendManager.sendFriendRequest(to: username, message: "Hi! I'd like to be your friend on HabitPilot AI.")
                
                await MainActor.run {
                    if success {
                        pendingRequests.insert(username)
                        alertMessage = "Friend request sent to \(username)!"
                        showingAlert = true
                    } else {
                        alertMessage = friendManager.errorMessage ?? "Failed to send friend request. You may already be friends or have a pending request."
                        showingAlert = true
                    }
                }
            }
        }
    }
}

#Preview {
    AddFriendView()
} 