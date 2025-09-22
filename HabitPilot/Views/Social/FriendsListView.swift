import SwiftUI

struct FriendsListView: View {
    @StateObject private var friendManager = FriendManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingActionSheet = false
    @State private var selectedFriend: Friend?
    @State private var showingProfileView = false
    @State private var selectedUser: User?
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            VStack {
                if friendManager.acceptedFriends.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No friends yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Add friends to see their progress and achievements")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(friendManager.acceptedFriends) { friend in
                            FriendRow(friend: friend) {
                                selectedFriend = friend
                                showingActionSheet = true
                            }
                        }
                    }
                    .refreshable {
                        await refreshFriends()
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Friend Actions", isPresented: $showingActionSheet) {
                if let friend = selectedFriend {
                    Button("View Profile") {
                        // Create a User object from Friend data
                        selectedUser = User(
                            id: friend.friendId,
                            username: friend.friendUsername,
                            email: nil,
                            createdAt: friend.createdAt,
                            lastLoginAt: friend.createdAt,
                            isAppleUser: false,
                            profilePicture: friend.profilePicture
                        )
                        showingProfileView = true
                    }
                    Button("Remove Friend", role: .destructive) {
                        Task {
                            await friendManager.removeFriend(friend)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            .sheet(isPresented: $showingProfileView) {
                if let user = selectedUser {
                    UserProfileDetailView(user: user)
                }
            }
        }
    }
    
    private func refreshFriends() async {
        isRefreshing = true
        await friendManager.refreshFriends()
        isRefreshing = false
    }
}

struct FriendRow: View {
    let friend: Friend
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Friend Avatar
                ProfileImageView(
                    username: friend.friendUsername,
                    size: 50
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.friendUsername)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Friends since \(friend.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FriendsListView()
} 