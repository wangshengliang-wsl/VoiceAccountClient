import SwiftUI

/// 声波动画视图
struct SoundWaveView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isAnimating: Bool
    
    @State private var waveHeights: [CGFloat] = Array(repeating: 0.3, count: 40)
    @State private var timer: Timer?
    
    private let columns = 40
    private let spacing: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    (colorScheme == .dark ? Color.white : Color.primary).opacity(0.8),
                                    (colorScheme == .dark ? Color.white : Color.primary).opacity(0.4)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: calculateBarWidth(geometry: geometry))
                        .frame(height: geometry.size.height * waveHeights[index])
                        .animation(.easeInOut(duration: 0.1), value: waveHeights[index])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: isAnimating) { _, animating in
            if animating {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func calculateBarWidth(geometry: GeometryProxy) -> CGFloat {
        let totalSpacing = spacing * CGFloat(columns - 1)
        let availableWidth = geometry.size.width - totalSpacing
        return availableWidth / CGFloat(columns)
    }
    
    private func startAnimation() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                for index in 0..<columns {
                    // 创建波浪效果，中间的柱子更高
                    let centerDistance = abs(CGFloat(index) - CGFloat(columns) / 2.0)
                    let normalizedDistance = centerDistance / CGFloat(columns / 2)
                    
                    // 基础高度随机变化
                    let randomHeight = CGFloat.random(in: 0.2...1.0)
                    
                    // 中间部分有更高的概率产生高柱
                    let centerBoost = (1.0 - normalizedDistance) * 0.5
                    
                    waveHeights[index] = min(randomHeight + centerBoost, 1.0)
                }
            }
        }
        
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
        
        withAnimation(.easeOut(duration: 0.3)) {
            for index in 0..<columns {
                waveHeights[index] = 0.3
            }
        }
    }
}

/// 脉冲圆环视图
struct PulseRingView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    
    let delay: Double
    
    var body: some View {
        Circle()
            .stroke((colorScheme == .dark ? Color.white : Color.primary).opacity(0.5), lineWidth: 3)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 2.0)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    scale = 2.5
                    opacity = 0.0
                }
            }
    }
}

#Preview {
    ZStack {
        Color.black
        SoundWaveView(isAnimating: .constant(true))
            .frame(height: 100)
            .padding()
    }
}

