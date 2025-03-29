//
//  ReverseView.swift
//  Reverse2048
//
//  Created by chang chiawei on 2025-03-29.
//

import SwiftUI

// MARK: - 遊戲邏輯 (Reverse 模式)
class Game2048Reverse: ObservableObject {
    @Published var board: [[Int]]
    @Published var gameOver: Bool = false
    @Published var message: String = ""
    
    let size = 4
    
    init() {
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        resetGame()
    }
    
    func resetGame() {
        gameOver = false
        message = ""
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        addRandomTile()
        addRandomTile()
    }
    
    func addRandomTile() {
        var emptyCells = [(Int, Int)]()
        for r in 0..<size {
            for c in 0..<size {
                if board[r][c] == 0 {
                    emptyCells.append((r, c))
                }
            }
        }
        if let cell = emptyCells.randomElement() {
            board[cell.0][cell.1] = 2048
        }
    }
    
    // 合併邏輯：相同的數字合併後除以2 (例如 2048 + 2048 -> 1024)
    func mergeLine(_ line: [Int]) -> [Int] {
        let arr = line.filter { $0 != 0 }
        var result: [Int] = []
        var skip = false
        for i in 0..<arr.count {
            if skip {
                skip = false
                continue
            }
            if i < arr.count - 1 && arr[i] == arr[i+1] {
                result.append(arr[i] / 2)
                skip = true
            } else {
                result.append(arr[i])
            }
        }
        while result.count < line.count {
            result.append(0)
        }
        return result
    }
    
    func move(_ direction: SwipeDirection) {
        guard !gameOver else { return }
        switch direction {
        case .left: moveLeft()
        case .right: moveRight()
        case .up: moveUp()
        case .down: moveDown()
        }
        addRandomTile()
        checkGameStatus()
    }
    
    func checkGameStatus() {
        // 這裡僅提供基本檢查：如果沒有空格且無法合併，則遊戲結束
        if board.flatMap({ $0 }).contains(0) == false && !hasMoves() {
            gameOver = true
            message = "Game Over"
        }
        // 如果所有數字都變成 0，則視為勝利
        if board.flatMap({ $0 }).allSatisfy({ $0 == 0 }) {
            gameOver = true
            message = "You Win!"
        }
    }
    
    func hasMoves() -> Bool {
        for r in 0..<size {
            for c in 0..<size-1 {
                if board[r][c] == board[r][c+1] {
                    return true
                }
            }
        }
        for c in 0..<size {
            for r in 0..<size-1 {
                if board[r][c] == board[r+1][c] {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - 移動邏輯
    func moveLeft() {
        for r in 0..<size {
            board[r] = mergeLine(board[r])
        }
    }
    
    func moveRight() {
        for r in 0..<size {
            // 將 row 轉成 Array 後再處理
            var row = Array(board[r].reversed())
            row = mergeLine(row)
            board[r] = Array(row.reversed())
        }
    }
    
    func moveUp() {
        for c in 0..<size {
            var col = (0..<size).map { board[$0][c] }
            col = mergeLine(col)
            for r in 0..<size {
                board[r][c] = col[r]
            }
        }
    }
    
    func moveDown() {
        for c in 0..<size {
            // 將 column 轉成 Array 後再處理
            var col = Array((0..<size).map { board[$0][c] }.reversed())
            col = mergeLine(col)
            let newCol = Array(col.reversed())
            for r in 0..<size {
                board[r][c] = newCol[r]
            }
        }
    }
}

// MARK: - UI Components

// 因為 Reverse 模式不使用障礙，所以直接使用 TileView 顯示數字
struct TileViewReverse: View {
    let value: Int
    let isObstacle: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
            if value != 0 {
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(textColor)
            }
        }
        .frame(width: 70, height: 70)
        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 2, y: 2)
    }
    
    var backgroundColor: Color {
        if isObstacle {
            return Color.red
        }
        if value == 0 {
            return Color(red: 205/255, green: 193/255, blue: 180/255)
        }
        return tileBackground(for: value)
    }
    
    func tileBackground(for number: Int) -> Color {
        switch number {
        case 2048: return Color(red: 237/255, green: 194/255, blue: 46/255)
        default:   return Color(red: 238/255, green: 228/255, blue: 218/255)
        }
    }
    
    var textColor: Color {
        if value == 2048 {
            return Color.white
        }
        return Color.black
    }
}

// 為 Reverse 模式新增專用的棋盤視圖
struct GameBoardReverseView: View {
    @ObservedObject var game: Game2048Reverse
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<game.size, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(0..<game.size, id: \.self) { c in
                        // Reverse 模式沒有障礙標示，所以 isObstacle 固定為 false
                        TileViewReverse(value: game.board[r][c], isObstacle: false)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(red: 187/255, green: 173/255, blue: 160/255))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

// MARK: - 主遊戲畫面
struct ReverseView: View {
    @StateObject private var game = Game2048Reverse()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Reverse 2048")
                .font(.largeTitle)
            Spacer()
            GameBoardReverseView(game: game)
            Spacer()
            if game.gameOver {
                Text(game.message)
                    .font(.title)
                    .foregroundColor(.red)
            }
            Button("New Game") {
                game.resetGame()
            }
            .padding()
        }
        .gesture(DragGesture(minimumDistance: 20).onEnded { value in
            let horizontal = value.translation.width
            let vertical = value.translation.height
            withAnimation {
                if abs(horizontal) > abs(vertical) {
                    game.move(horizontal < 0 ? .left : .right)
                } else {
                    game.move(vertical < 0 ? .up : .down)
                }
            }
        })
    }
}

// MARK: - 預覽
struct ReverseView_Previews: PreviewProvider {
    static var previews: some View {
        ReverseView()
    }
}

