import SwiftUI

struct SocialSearchView: View {
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendManager = FriendManager.shared
    @State private var selectedFilter: SearchFilter = .all
    
    enum SearchFilter: String, CaseIterable {
        case all = "All"
        case friends = "Friends"
        case challenges = "Challenges"

        
        var icon: String {
            switch self {
            case .all: return "magnifyingglass"
            case .friends: return "person.2.fill"
            case .challenges: return "trophy.fill"
    
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .friends: return Color(hex: "#FF6B9D")
            case .challenges: return Color(hex: "#FF6B35")
    
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search friends", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: searchText) { _ in
                                Task {
                                    await friendManager.searchUsers(query: searchText)
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondaryBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SearchFilter.allCases, id: \.self) { filter in
                                SearchFilterButton(
                                    filter: filter,
                                    isSelected: selectedFilter == filter,
                                    action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedFilter = filter
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Search Results
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if friendManager.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 100)
                        } else if searchText.isEmpty {
                            EmptySearchState()
                        } else if friendManager.searchResults.isEmpty {
                            NoResultsState(searchText: searchText)
                        } else {
                            ForEach(friendManager.searchResults) { user in
                                SearchResultCard(user: user, filter: selectedFilter)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Search Filter Button
struct SearchFilterButton: View {
    let filter: SocialSearchView.SearchFilter
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [filter.color, filter.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [filter.color.opacity(0.15), filter.color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? filter.color.opacity(0.3) : filter.color.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Search Result Card
struct SearchResultCard: View {
    let user: User
    let filter: SocialSearchView.SearchFilter
    @State private var isPressed = false
    @StateObject private var friendManager = FriendManager.shared
    @State private var isSendingRequest = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingProfile = false
    
    private var isAlreadyFriend: Bool {
        friendManager.friends.contains { $0.friendUsername.lowercased() == user.username.lowercased() }
    }
    
    private var hasPendingRequest: Bool {
        friendManager.outgoingRequests.contains { $0.toUsername.lowercased() == user.username.lowercased() }
    }
    
    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                filter.color.opacity(0.15),
                filter.color.opacity(0.08),
                filter.color.opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var strokeGradient: LinearGradient {
        LinearGradient(
            colors: [
                filter.color.opacity(0.4),
                filter.color.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ProfileImageView(
                username: user.username,
                size: 50
            )
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Member since \(user.createdAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Button
            if isAlreadyFriend {
                Text("Friends")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.2))
                    )
            } else if hasPendingRequest {
                Text("Request Sent")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.2))
                    )
            } else {
                Button(action: {
                    Task {
                        isSendingRequest = true
                        let success = await friendManager.sendFriendRequest(to: user.username)
                        if success {
                            alertMessage = "Friend request sent to \(user.username)!"
                        } else {
                            alertMessage = friendManager.errorMessage ?? "Failed to send friend request"
                        }
                        showingAlert = true
                        isSendingRequest = false
                    }
                }) {
                    Text(isSendingRequest ? "Sending..." : "Add Friend")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [filter.color, filter.color.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .disabled(isSendingRequest)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(strokeGradient, lineWidth: 1.5)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            showingProfile = true
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .alert("Friend Request", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingProfile) {
            UserProfileDetailView(user: user)
        }
    }
}

// MARK: - Empty Search State
struct EmptySearchState: View {
    private var emptyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.1),
                Color.blue.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(emptyGradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Search for friends, challenges, and groups")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Start typing to find what you're looking for")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondaryBackground)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .padding(.top, 100)
    }
}

// MARK: - No Results State
struct NoResultsState: View {
    let searchText: String
    
    private var emptyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.orange.opacity(0.1),
                Color.orange.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(emptyGradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 8) {
                Text("No results found")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("No results found for '\(searchText)'")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondaryBackground)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .padding(.top, 100)
    }
} 