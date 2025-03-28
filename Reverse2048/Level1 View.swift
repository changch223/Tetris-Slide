//
//  Level1 View.swift
//  Reverse2048
//
//  Created by chang chiawei on 2025-03-28.
//

import SwiftUI

enum SwipeDirection { case left, right, up, down }

class Game2048Obstacle: ObservableObject {
    @Published var board: [[Int]]
    @Published var moveCount = 0
    @Published var gameOver = false
    @Published var message = ""
    
    // 障礙值獨立記錄，同時儲存在棋盤右下角
    @Published var obstacle: Int = 2048
    
    let size = 4
    let maxMoves = 100
    
    init() {
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        resetGame()
    }
    
    func resetGame() {
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        obstacle = 2048
        moveCount = 0
        gameOver = false
        message = ""
        addRandomTile()
        addRandomTile()
        // 固定障礙：右下角
        board[size-1][size-1] = obstacle
    }
    
    func addRandomTile() {
        var emptyCells = [(Int, Int)]()
        for r in 0..<size {
            for c in 0..<size {
                // 排除障礙位置
                if r == size-1 && c == size-1 { continue }
                if board[r][c] == 0 {
                    emptyCells.append((r, c))
                }
            }
        }
        if let cell = emptyCells.randomElement() {
            board[cell.0][cell.1] = Bool.random() ? 2 : 4
        }
    }
    
    // 標準合併函數，依 2048 規則合併相同數字
    func mergeLine(_ line: [Int]) -> [Int] {
        var arr = line.filter { $0 != 0 }
        var result: [Int] = []
        var skip = false
        for i in 0..<arr.count {
            if skip {
                skip = false
                continue
            }
            if i < arr.count - 1 && arr[i] == arr[i+1] {
                result.append(arr[i] * 2)
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
    
    // 根據滑動方向呼叫對應邏輯
    func move(_ direction: SwipeDirection) {
        guard !gameOver else { return }
        let original = board
        switch direction {
        case .left:
            moveLeft()
        case .right:
            moveRight()
        case .up:
            moveUp()
        case .down:
            moveDown()
        }
        if board != original {
            moveCount += 1
            addRandomTile()
            checkGameStatus()
        }
    }
    
    func checkGameStatus() {
        if obstacle <= 0 {
            message = "🎉 你贏了！"
            gameOver = true
        } else if moveCount >= maxMoves {
            message = "步數用盡，遊戲失敗！"
            gameOver = true
        }
        // 每次更新後，確保障礙位置數值正確
        board[size-1][size-1] = obstacle
    }
    
    // MARK: - 各方向移動邏輯
    // 向左移動：對最後一列僅處理前 3 格，障礙保持不動
    func moveLeft() {
        for r in 0..<size {
            if r == size-1 {
                var segment = Array(board[r][0..<size-1])
                segment = mergeLine(segment)
                for c in 0..<size-1 {
                    board[r][c] = segment[c]
                }
                // 障礙 (col 3) 保持不變
            } else {
                board[r] = mergeLine(board[r])
            }
        }
    }
    
    // 向右移動：對最後一列先處理前 3 格（反向合併），再檢查是否可與障礙合併
    func moveRight() {
        for r in 0..<size {
            if r == size-1 {
                var segment = Array(board[r][0..<size-1])
                segment.reverse()
                segment = mergeLine(segment)
                segment.reverse()
                // 特殊處理：檢查最靠近障礙的數字是否能與障礙合併
                if let A = segment.last, A != 0, obstacle > A {
                    obstacle -= A * A
                    segment[segment.count - 1] = 0
                }
                for c in 0..<size-1 {
                    board[r][c] = segment[c]
                }
            } else {
                var row = board[r]
                row.reverse()
                row = mergeLine(row)
                row.reverse()
                board[r] = row
            }
        }
    }
    
    // 向上移動：對最後一行所在的最後一欄僅處理前 3 個數值
    func moveUp() {
        for c in 0..<size {
            if c == size-1 {
                var col = [Int]()
                for r in 0..<size-1 {
                    col.append(board[r][c])
                }
                col = mergeLine(col)
                for r in 0..<size-1 {
                    board[r][c] = col[r]
                }
                // 障礙 (row 3) 保持不動
            } else {
                var col = [Int]()
                for r in 0..<size {
                    col.append(board[r][c])
                }
                col = mergeLine(col)
                for r in 0..<size {
                    board[r][c] = col[r]
                }
            }
        }
    }
    
    // 向下移動：對最後一欄先處理前 3 格（反向合併），再檢查是否可與障礙合併
    func moveDown() {
        for c in 0..<size {
            if c == size-1 {
                var col = [Int]()
                for r in 0..<size-1 {
                    col.append(board[r][c])
                }
                col.reverse()
                col = mergeLine(col)
                col.reverse()
                // 特殊處理：檢查最靠近障礙的數字是否能與障礙合併
                if let A = col.last, A != 0, obstacle > A {
                    obstacle -= A * A
                    col[col.count - 1] = 0
                }
                for r in 0..<size-1 {
                    board[r][c] = col[r]
                }
            } else {
                var col = [Int]()
                for r in 0..<size {
                    col.append(board[r][c])
                }
                col.reverse()
                col = mergeLine(col)
                col.reverse()
                for r in 0..<size {
                    board[r][c] = col[r]
                }
            }
        }
    }
}


// MARK: - UI Components

struct GameView: View {
    let difficulty: String
    
    @ObservedObject var game = Game2048Obstacle()

    var body: some View {
        VStack(spacing: 20) {
            Text("步數: \(game.moveCount)/100").font(.title)
            Text(game.message).foregroundColor(.red)

            VStack(spacing: 4) {
                ForEach(0..<game.size, id: \..self) { r in
                    HStack(spacing: 4) {
                        ForEach(0..<game.size, id: \..self) { c in
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(r == game.size-1 && c == game.size-1 ? Color.red : Color.gray.opacity(0.3))
                                Text(r == game.size-1 && c == game.size-1 ? "\(game.obstacle)" : game.board[r][c] != 0 ? "\(game.board[r][c])" : "")
                                    .font(.headline)
                                    .foregroundColor(.black)
                            }
                            .frame(width: 70, height: 70)
                        }
                    }
                }
            }
            .gesture(DragGesture(minimumDistance: 20).onEnded({ value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height
                if abs(horizontalAmount) > abs(verticalAmount) {
                    game.move(horizontalAmount < 0 ? .left : .right)
                } else {
                    game.move(verticalAmount < 0 ? .up : .down)
                }
            }))

            Button("重新開始") { game.resetGame() }
                .padding().background(Color.blue).foregroundColor(.white).cornerRadius(8)
        }.padding()
    }
}

