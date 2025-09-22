import SwiftUI

struct LaunchView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 1.0
    
    let onTransitionComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Clean gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue,
                    Color.blue.opacity(0.8),
                    Color.blue.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)
            
            VStack(spacing: 40) {
                // HabitPilot logo with rounded corners and minimal container
                ZStack {
                    // Very subtle rounded background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                        .opacity(logoOpacity)
                        .animation(.easeInOut(duration: 0.8), value: logoOpacity)
                    
                    // HabitPilot logo with rounded corners
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 105, height: 105)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .opacity(logoOpacity)
                        .animation(.easeInOut(duration: 0.8), value: logoOpacity)
                }
                
                VStack(spacing: 12) {
                    // App name
                    Text("HabitPilot AI")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .opacity(textOpacity)
                        .animation(.easeInOut(duration: 0.6).delay(0.3), value: textOpacity)
                    
                    // Tagline
                    Text("Build Better Habits")
                        .font(.system(size: 18, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(textOpacity)
                        .animation(.easeInOut(duration: 0.6).delay(0.5), value: textOpacity)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Initial animation
        withAnimation(.easeInOut(duration: 0.8)) {
            logoOpacity = 1.0
        }
        
        // Text animation
        withAnimation(.easeInOut(duration: 0.6).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Transition to main app after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.7)) {
                logoOpacity = 0.0
                textOpacity = 0.0
                backgroundOpacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                onTransitionComplete()
            }
        }
    }
}

#Preview {
    LaunchView {
        print("Transition complete")
    }
} 