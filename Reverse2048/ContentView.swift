//
//  ContentView.swift
//  Reverse2048
//
//  Created by chang chiawei on 2025-03-28.
//
import SwiftUI
import AVFoundation

struct DifficultyOption: Identifiable {
    let id = UUID()
    let key: String
    let labelKey: LocalizedStringKey
    let subText: String
}

let difficulties: [DifficultyOption] = [
    DifficultyOption(key: "traditional", labelKey: "traditional", subText: "邏輯逆轉，步步驚心"),
    DifficultyOption(key: "classic", labelKey: "classic", subText: "經典回歸，你能撐幾步？"),
    DifficultyOption(key: "level_promax", labelKey: "level_promax", subText: "超難挑戰，沒在開玩笑")
]

struct ContentView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var isPressed: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var pressedButtonKey: String? = nil

    func playClickSound() {
        if let url = Bundle.main.url(forResource: "Click", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("Failed to play sound: \(error)")
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 新背景：紫藍偏暗（避免和2048撞色）
                LinearGradient(gradient: Gradient(colors: [Color(red: 64/255, green: 64/255, blue: 122/255), Color(red: 38/255, green: 38/255, blue: 68/255)]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 10) {
                    // Logo 動畫
                    Image("image")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                        .scaleEffect(isPressed ? 0.9 : logoScale)
                        .opacity(logoOpacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                isPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring()) {
                                    isPressed = false
                                }
                            }
                            playClickSound()
                        }
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.6)) {
                                logoOpacity = 1.0
                                logoScale = 1.0
                            }
                        }

                    // 主標題
                    Text(LocalizedStringKey("tile_rewind"))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    // 副標題
                    Text("超高難度數字合併與障礙清除玩法")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 20)

                    // 提示動畫
                    Text("選一個模式開始挑戰吧 💥")
                        .font(.footnote)
                        .foregroundColor(.yellow)
                        .opacity(0.8)
                        .padding(.bottom, 10)

                    // 難易度按鈕
                    ForEach(difficulties) { difficulty in
                        VStack(spacing: 6) {
                            NavigationLink {
                                switch difficulty.key {
                                case "traditional":
                                    ReverseGameViewShared()
                                case "level_promax":
                                    GameViewSharedProMax()
                                case "classic":
                                    GameViewShared()
                                default:
                                    EmptyView()
                                }
                            } label: {
                                Text(difficulty.labelKey)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 60)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(radius: 3)
                                    .scaleEffect(pressedButtonKey == difficulty.key ? 0.95 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressedButtonKey)
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        pressedButtonKey = difficulty.key
                                        playClickSound()
                                    }
                                    .onEnded { _ in
                                        pressedButtonKey = nil
                                    }
                            )

                            Text(difficulty.subText)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    Spacer(minLength: 30)

                    NavigationLink(destination: AboutView()) {
                        Text("🔍 關於這款遊戲 / About")
                            .font(.footnote)
                            .foregroundColor(.blue)
                            .underline()
                    }

                    Text("効果音：OtoLogic (https://otologic.jp)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)

                    BannerAdView(adUnitID: "ca-app-pub-9275380963550837/8710922047")
                        .frame(height: 50)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
}
