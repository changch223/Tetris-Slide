//
//  ContentView.swift
//  Reverse2048
//
//  Created by chang chiawei on 2025-03-28.
//

import SwiftUI

struct ContentView: View {
    let difficulties = ["Easy", "Medium", "Hard", "Extreme"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Reverse 2048")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                Spacer()
                
                ForEach(difficulties, id: \.self) { difficulty in
                    NavigationLink(destination: GameView(difficulty: difficulty)) {
                        Text(difficulty)
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
        }
    }
}


#Preview {
    ContentView()
}
