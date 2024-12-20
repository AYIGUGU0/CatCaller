import SwiftUI
import AVFoundation

// 添加 Color 扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView: View {
    @State private var audioPlayers: [AVAudioPlayer?] = Array(repeating: nil, count: 9)
    @State private var pressedIndex: Int? = nil
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let feedback = UIImpactFeedbackGenerator(style: .medium)
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
    }
    
    var body: some View {
        ZStack {
            // 背景颜色
            Color(hex: "F7F6F2")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Banner 图
                Image("banner")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .padding(.top, 20)
                
                // 按钮网格 - 调整为3列，减小按钮大小
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(0..<9) { index in
                        Button(action: {
                            buttonTapped(index: index)
                        }) {
                            Image("cat\(index + 1)")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)
                                .scaleEffect(pressedIndex == index ? 0.9 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressedIndex == index)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .onAppear {
            loadSounds()
            feedback.prepare() // 预备触觉反馈
        }
        .onDisappear {
            audioPlayers.forEach { player in
                player?.stop()
            }
        }
    }
    
    private func buttonTapped(index: Int) {
        // 触觉反馈
        feedback.impactOccurred()
        
        // 按压动画
        pressedIndex = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedIndex = nil
        }
        
        // 播放声音
        playSound(index: index)
    }
    
    private func loadSounds() {
        // 预加载所有声音
        for i in 1...9 {
            if let soundURL = Bundle.main.url(forResource: "meow\(i)", withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.prepareToPlay()
                    audioPlayers[i-1] = player
                    print("成功加载声音：meow\(i).wav")
                } catch {
                    print("加载声音失败：meow\(i).wav，错误：\(error)")
                }
            } else {
                print("找不到声音文件：meow\(i).wav")
            }
        }
    }
    
    private func playSound(index: Int) {
        guard index < audioPlayers.count else { return }
        
        // 停止其他正在播放的声音
        audioPlayers.forEach { player in
            if player?.isPlaying == true {
                player?.stop()
                player?.currentTime = 0
            }
        }
        
        // 播放选中的声音
        if let player = audioPlayers[index] {
            if !player.isPlaying {
                player.currentTime = 0
                player.play()
                print("播放声音：\(index + 1)")
            }
        }
    }
}

#Preview {
    ContentView()
}
