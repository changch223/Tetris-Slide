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
}

let difficulties: [DifficultyOption] = [
    DifficultyOption(key: "classic", labelKey: "classic"),
    DifficultyOption(key: "level_promax", labelKey: "level_promax")
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
        NavigationStack {
            ZStack {
                // 背景色
                Color(red: 250/255, green: 248/255, blue: 239/255)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer() // 上方間距
                    
                    // 標題
                    Text(LocalizedStringKey("reverse_2048"))
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(Color(red: 119/255, green: 110/255, blue: 101/255))
                    
                    // Logo 圖片
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
                            // 回彈
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
                    
                    
                    
                    // 難易度按鈕
                    ForEach(difficulties) { difficulty in
                        NavigationLink {
                            switch difficulty.key {
                            case "classic":
                                GameViewShared()
                            case "level_promax":
                                GameViewSharedProMax()
                            default:
                                EmptyView()
                            }
                        } label: {
                            Text(difficulty.labelKey)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.vertical, 15)
                                .padding(.horizontal, 60)
                                .background(Color(red: 143/255, green: 122/255, blue: 102/255))
                                .cornerRadius(8)
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
                    }
                    
                    
                    Spacer(minLength: 60) // 下方間距
                    
                    Text("効果音：OtoLogic (https://otologic.jp)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                    
                    BannerAdView(adUnitID: "ca-app-pub-9275380963550837/8710922047")
                        .frame(height: 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
    
    }
}


#Preview {
    ContentView()
}
