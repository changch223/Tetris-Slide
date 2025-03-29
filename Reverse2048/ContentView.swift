//
//  ContentView.swift
//  Reverse2048
//
//  Created by chang chiawei on 2025-03-28.
//

import SwiftUI

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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 與 2048 相同的背景色 #faf8ef
                Color(red: 250/255, green: 248/255, blue: 239/255)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 40) {
                    // 標題
                    Text(LocalizedStringKey("reverse_2048"))
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(Color(red: 119/255, green: 110/255, blue: 101/255))
                        .padding(.top, 40)
                    
                    Spacer()
                    
                    // 難易度選擇按鈕
                    VStack(spacing: 20) {
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
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            // 隱藏預設的 NavigationBar 標題
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
}
