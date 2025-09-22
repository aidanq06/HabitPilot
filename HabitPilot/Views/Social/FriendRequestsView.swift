import SwiftUI

struct FriendRequestsView: View {
    @StateObject private var friendManager = FriendManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingErrorAlert = false
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            VStack {
                if friendManager.pendingRequests.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No friend requests")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("When someone sends you a friend request, it will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            
                        // Refresh button for when there are sync issues
                        Button(action: {
                            Task {
                                isRefreshing = true
                                await friendManager.forceRefresh()
                                isRefreshing = false
                            }
                        }) {
                            HStack {
                                if isRefreshing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("Refresh")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .disabled(isRefreshing)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(friendManager.pendingRequests) { request in
                            FriendRequestRow(request: request)
                        }
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isRefreshing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Button(action: {
                            Task {
                                isRefreshing = true
                                await friendManager.forceRefresh()
                                isRefreshing = false
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Sync with API when view appears to ensure we have latest data
                Task {
                    await friendManager.syncWithAPI()
                }
            }
            .onChange(of: friendManager.errorMessage) { error in
                if error != nil {
                    showingErrorAlert = true
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") {
                    friendManager.errorMessage = nil
                }
            } message: {
                Text(friendManager.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

struct FriendRequestRow: View {
    let request: FriendRequest
    @StateObject private var friendManager = FriendManager.shared
    @State private var showingActionSheet = false
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // User Avatar
            ProfileImageView(
                username: request.fromUsername,
                size: 50
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.fromUsername)
                    .font(.headline)
                
                if let message = request.message, !message.isEmpty {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("Sent \(request.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
            } else {
                HStack(spacing: 8) {
                    Button("Accept") {
                        isProcessing = true
                        Task {
                            await friendManager.acceptFriendRequest(request)
                            isProcessing = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(isProcessing)
                    
                    Button("Decline") {
                        isProcessing = true
                        Task {
                            await friendManager.declineFriendRequest(request)
                            isProcessing = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(isProcessing)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FriendRequestsView()
} 