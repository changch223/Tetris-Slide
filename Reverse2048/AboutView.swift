//
//  AboutView.swift
//  Reverse2048
//
//  Created by chang chiawei on 2025-03-31.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("About This Game")
                    .font(.title)
                    .fontWeight(.bold)

                Text("This is an original puzzle where numbers split and subtract instead of merge — a reverse take on the tile-matching genre.")
                
                Text("Inspired by the original 2048 by Gabriele Cirulli, this game introduces reversed logic and new challenges including obstacles, subtraction mechanics, and extremely difficult levels.")
                
                Text("All game logic, UI, art style, and sound design were independently used for this app.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
