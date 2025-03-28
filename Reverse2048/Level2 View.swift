//
//  GameViewHard.swift
//  Reverse2048
//
//  Created by YourName on 2025-03-28.
//
//  說明：本版本依照 HTML 版難度規則進行調整：
//         • 步數上限 50 步
//         • 右下角障礙初始值 4096
//         • 每次成功移動後隨機新增兩個方塊（80% 為 2，15% 為 4，5% 為 8）
//         • 只有當移動方向是向障礙（右或下）時，會對障礙鄰近的數字進行特殊合併：
//           若障礙旁數字 A ≠ 0 且障礙值 > A，則障礙扣除 A²，並清除該方塊
//

import SwiftUI



class Game2048ObstacleLevel2: ObservableObject {
    @Published var board: [[Int]]
    @Published var moveCount = 0
    @Published var obstacle = 4096   // 初始障礙值：4096
    @Published var gameOver = false
    @Published var message = ""
    
    let size = 4
    let maxMoves = 50              // 步數限制 50 步
    
    init() {
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        resetGame()
    }
    
    func resetGame() {
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        obstacle = 4096
        moveCount = 0
        gameOver = false
        message = ""
        // 初始隨機新增兩個方塊（障礙位置除外）
        addRandomTile()
        addRandomTile()
        board[size-1][size-1] = obstacle
    }
    
    // 新增隨機方塊：80% 為 2，15% 為 4，5% 為 8
    func addRandomTile() {
        var emptyCells = [(Int, Int)]()
        for r in 0..<size {
            for c in 0..<size {
                if r == size-1 && c == size-1 { continue } // 障礙位置不新增
                if board[r][c] == 0 {
                    emptyCells.append((r, c))
                }
            }
        }
        if let cell = emptyCells.randomElement() {
            let rand = Double.random(in: 0...1)
            let tileValue: Int
            if rand < 0.8 {
                tileValue = 2
            } else if rand < 0.95 {
                tileValue = 4
            } else {
                tileValue = 8
            }
            board[cell.0][cell.1] = tileValue
        }
    }
    
    // 根據方向進行移動（成功移動才算步，並隨後新增兩個隨機方塊）
    func move(_ direction: SwipeDirection) {
        guard !gameOver else { return }
        let original = board
        switch direction {
        case .left:
            shiftHorizontally(reverse: false)
        case .right:
            shiftHorizontally(reverse: true)
        case .up:
            shiftVertically(reverse: false)
        case .down:
            shiftVertically(reverse: true)
        }
        if board != original {
            moveCount += 1
            // 每次成功移動後新增兩個隨機方塊
            addRandomTile()
            addRandomTile()
            checkGameStatus()
        }
    }
    
    // 檢查勝利（障礙值 ≤ 0）與失敗（步數達上限）
    func checkGameStatus() {
        if obstacle <= 0 {
            message = "🎉 你贏了！"
            gameOver = true
        } else if moveCount >= maxMoves {
            message = "步數用盡，遊戲失敗！"
            gameOver = true
        }
        // 確保障礙數值正確（右下角固定）
        board[size-1][size-1] = obstacle
    }
    
    // MARK: - 移動處理
    
    // 橫向移動：
    // 對於非障礙列照常處理，
    // 對於最後一列（障礙所在列），只針對前 3 格進行處理，
    // 若向右移動（reverse 為 true），先反轉前 3 格，再合併，最後再反轉回原序
    func shiftHorizontally(reverse: Bool) {
        for r in 0..<size {
            if r == size - 1 {
                // 針對最後一列，只處理前 3 格
                let segment = board[r][0..<size-1]
                let workingSegment = reverse ? Array(segment.reversed()) : Array(segment)
                let merged = merge(line: workingSegment, applyObstacleMerge: reverse)
                let finalSegment = reverse ? Array(merged.reversed()) : merged
                for c in 0..<size-1 {
                    board[r][c] = finalSegment[c]
                }
                // 障礙位置保持不變
                board[r][size-1] = obstacle
            } else {
                var row = board[r]
                if reverse { row.reverse() }
                let merged = merge(line: row, applyObstacleMerge: false)
                row = reverse ? merged.reversed() : merged
                board[r] = row
            }
        }
    }
    
    // 縱向移動：
    // 對於障礙所在欄，僅處理前 3 格（rows 0 ~ size-2），其他欄則全部處理
    func shiftVertically(reverse: Bool) {
        for c in 0..<size {
            if c == size-1 {
                // 障礙所在欄，只處理前 3 格
                var col = (0..<size-1).map { board[$0][c] }
                if reverse { col.reverse() }
                let merged = merge(line: col, applyObstacleMerge: reverse)
                let finalSegment = reverse ? Array(merged.reversed()) : merged
                for r in 0..<size-1 {
                    board[r][c] = finalSegment[r]
                }
                // 障礙位置保持不變
            } else {
                var col = (0..<size).map { board[$0][c] }
                if reverse { col.reverse() }
                let merged = merge(line: col, applyObstacleMerge: false)
                let finalSegment = reverse ? Array(merged.reversed()) : merged
                for r in 0..<size {
                    board[r][c] = finalSegment[r]
                }
            }
        }
    }
    
    // 合併函數：先依 2048 規則合併數字，
    // 若 applyObstacleMerge 為 true（表示此次移動朝向障礙），則對最靠近障礙的數字 A：
    // 若 A ≠ 0 且障礙值 > A，則障礙扣除 A²，同時清除該方塊（置 0）
    func merge(line: [Int], applyObstacleMerge: Bool) -> [Int] {
        var nonZero = line.filter { $0 != 0 }
        var merged: [Int] = []
        var skip = false
        for i in 0..<nonZero.count {
            if skip {
                skip = false
                continue
            }
            if i < nonZero.count - 1 && nonZero[i] == nonZero[i+1] {
                merged.append(nonZero[i] * 2)
                skip = true
            } else {
                merged.append(nonZero[i])
            }
        }
        if applyObstacleMerge && !merged.isEmpty {
            let A = merged.last!
            if A != 0 && obstacle > A {
                obstacle -= A * A
                merged.removeLast()
                merged.append(0)
            }
        }
        while merged.count < line.count {
            merged.append(0)
        }
        return merged
    }
}

struct GameViewMedium: View {
    let difficulty: String
    
    @ObservedObject var game = Game2048ObstacleLevel2()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("步數: \(game.moveCount)/\(game.maxMoves)")
                .font(.title)
            Text(game.message)
                .foregroundColor(.red)
            
            VStack(spacing: 4) {
                ForEach(0..<game.size, id: \.self) { r in
                    HStack(spacing: 4) {
                        ForEach(0..<game.size, id: \.self) { c in
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill((r == game.size-1 && c == game.size-1)
                                          ? Color.red
                                          : Color.gray.opacity(0.3))
                                Text((r == game.size-1 && c == game.size-1)
                                     ? "\(game.obstacle)"
                                     : (game.board[r][c] != 0 ? "\(game.board[r][c])" : ""))
                                    .font(.headline)
                                    .foregroundColor(.black)
                            }
                            .frame(width: 70, height: 70)
                        }
                    }
                }
            }
            .gesture(DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    if abs(horizontal) > abs(vertical) {
                        game.move(horizontal < 0 ? .left : .right)
                    } else {
                        game.move(vertical < 0 ? .up : .down)
                    }
                }
            )
            
            Button("重新開始") {
                game.resetGame()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

struct GameViewMedium_Previews: PreviewProvider {
    static var previews: some View {
        GameViewMedium(difficulty: "Hard")
    }
}
