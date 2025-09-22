import SwiftUI

struct ProgressBar: View {
    let progress: Double
    let backgroundColor: Color
    let progressColor: Color
    let height: CGFloat
    let animated: Bool
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, backgroundColor: Color = .tertiaryBackground, progressColor: Color = .successGreen, height: CGFloat = 8, animated: Bool = true) {
        self.progress = progress
        self.backgroundColor = backgroundColor
        self.progressColor = progressColor
        self.height = height
        self.animated = animated
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                
                // Progress bar
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [progressColor, progressColor.lighter(by: 0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (animated ? animatedProgress : progress))
                    .overlay(
                        // Shimmer effect
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (animated ? animatedProgress : progress))
                            .mask(
                                RoundedRectangle(cornerRadius: height / 2)
                                    .frame(width: geometry.size.width * (animated ? animatedProgress : progress))
                            )
                    )
                    .animation(.easeInOut(duration: 1.0), value: animatedProgress)
            }
        }
        .frame(height: height)
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            if animated {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedProgress = newValue
                }
            }
        }
    }
}

// MARK: - Circular Progress Bar

struct CircularProgressBar: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let backgroundColor: Color
    let progressColor: Color
    let animated: Bool
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, size: CGFloat = 60, lineWidth: CGFloat = 8, backgroundColor: Color = .tertiaryBackground, progressColor: Color = .successGreen, animated: Bool = true) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.backgroundColor = backgroundColor
        self.progressColor = progressColor
        self.animated = animated
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animated ? animatedProgress : progress)
                .stroke(
                    LinearGradient(
                        colors: [progressColor, progressColor.lighter(by: 0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.5), value: animatedProgress)
        }
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 1.5).delay(0.3)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            if animated {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedProgress = newValue
                }
            }
        }
    }
}

// MARK: - Wave Progress Bar

struct WaveProgressBar: View {
    let progress: Double
    let backgroundColor: Color
    let progressColor: Color
    let height: CGFloat
    let animated: Bool
    @State private var animatedProgress: Double = 0
    @State private var waveOffset: Double = 0
    
    init(progress: Double, backgroundColor: Color = .tertiaryBackground, progressColor: Color = .successGreen, height: CGFloat = 8, animated: Bool = true) {
        self.progress = progress
        self.backgroundColor = backgroundColor
        self.progressColor = progressColor
        self.height = height
        self.animated = animated
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                
                // Wave progress
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * (animated ? animatedProgress : progress))
                    .overlay(
                        // Wave effect
                        WaveShape(offset: waveOffset)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: geometry.size.width * (animated ? animatedProgress : progress))
                            .mask(
                                RoundedRectangle(cornerRadius: height / 2)
                                    .frame(width: geometry.size.width * (animated ? animatedProgress : progress))
                            )
                    )
                    .animation(.easeInOut(duration: 1.0), value: animatedProgress)
            }
        }
        .frame(height: height)
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                    animatedProgress = progress
                }
                
                // Start wave animation
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    waveOffset = 1.0
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            if animated {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedProgress = newValue
                }
            }
        }
    }
}

struct WaveShape: Shape {
    let offset: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for x in stride(from: 0, through: width, by: 1) {
            let normalizedX = x / width
            let wave = sin(normalizedX * .pi * 4 + offset * .pi * 2) * height * 0.1
            let y = height * 0.5 + wave
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Pulse Progress Bar

struct PulseProgressBar: View {
    let progress: Double
    let backgroundColor: Color
    let progressColor: Color
    let height: CGFloat
    let animated: Bool
    @State private var animatedProgress: Double = 0
    @State private var isPulsing = false
    
    init(progress: Double, backgroundColor: Color = .tertiaryBackground, progressColor: Color = .successGreen, height: CGFloat = 8, animated: Bool = true) {
        self.progress = progress
        self.backgroundColor = backgroundColor
        self.progressColor = progressColor
        self.height = height
        self.animated = animated
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                
                // Progress bar
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * (animated ? animatedProgress : progress))
                    .scaleEffect(isPulsing ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 1.0), value: animatedProgress)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            }
        }
        .frame(height: height)
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                    animatedProgress = progress
                }
                
                // Start pulse animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            if animated {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedProgress = newValue
                }
            }
        }
    }
}

// MARK: - Progress Bar with Label

struct LabeledProgressBar: View {
    let title: String
    let progress: Double
    let subtitle: String?
    let height: CGFloat
    let backgroundColor: Color
    let progressColor: Color
    let animated: Bool
    
    init(
        title: String,
        progress: Double,
        subtitle: String? = nil,
        height: CGFloat = 8,
        backgroundColor: Color = Color.secondaryBackground,
        progressColor: Color = Color.successGreen,
        animated: Bool = true
    ) {
        self.title = title
        self.progress = max(0, min(1, progress))
        self.subtitle = subtitle
        self.height = height
        self.backgroundColor = backgroundColor
        self.progressColor = progressColor
        self.animated = animated
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            
            ProgressBar(
                progress: progress,
                backgroundColor: backgroundColor,
                progressColor: progressColor,
                height: height,
                animated: animated
            )
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        LabeledProgressBar(
            title: "Daily Progress",
            progress: 0.75,
            subtitle: "6 of 8 completed"
        )
        
        ProgressBar(
            progress: 0.6,
            height: 12
        )
        
        CircularProgressBar(
            progress: 0.85,
            size: 80
        )
    }
    .padding()
} 