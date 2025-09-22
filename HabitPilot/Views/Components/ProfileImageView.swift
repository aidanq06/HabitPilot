import SwiftUI

struct ProfileImageView: View {
    let username: String?
    let size: CGFloat
    
    init(username: String?, size: CGFloat = 100) {
        self.username = username
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Text(firstLetter)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            )
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var firstLetter: String {
        guard let username = username, !username.isEmpty else {
            return "?"
        }
        return String(username.prefix(1)).capitalized
    }
}

struct ProfileImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ProfileImageView(username: "John", size: 100)
            ProfileImageView(username: "alice", size: 60)
            ProfileImageView(username: nil, size: 80)
        }
    }
} 