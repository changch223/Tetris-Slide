//
//  Classic View.swift
//  Reverse2048
//
//  Created by chang chiawei on 2025-03-28.
//

import SwiftUI

enum Difficulty: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case easy
    case medium

    // Localized text label
    var label: Text {
        switch self {
        case .easy:
            return Text("difficulty_easy")
        case .medium:
            return Text("difficulty_medium")
        }
    }
}

// MARK: - 遊戲邏輯
enum SwipeDirection { case left, right, up, down }

class Game2048Obstacle: ObservableObject {
    @Published var board: [[Int]]
    // 記錄已使用的步數，剩餘步數 = maxMoves - moveCount
    @Published var moveCount: Int = 0
    @Published var gameOver: Bool = false
    @Published var message: String = ""
    
    // 障礙值獨立記錄，同時儲存在棋盤右下角
    @Published var obstacle: Int
    
    let size = 4
    var maxMoves: Int
    var difficulty: Difficulty
    
    init(difficulty: Difficulty = .easy) {
        self.difficulty = difficulty
        // 根據難易度設定步數上限與障礙初始值
        switch difficulty {
        case .easy:
            self.maxMoves = 50
            self.obstacle = 2048
        case .medium:
            self.maxMoves = 50
            self.obstacle = 4096
        }
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        resetGame()
    }
    
    // 新增一個可選參數 newDifficulty，若傳入則依新難易度更新設定
    func resetGame(newDifficulty: Difficulty? = nil) {
        // 若有傳入新難易度則更新難易度與相關參數
        if let diff = newDifficulty {
            self.difficulty = diff
            switch diff {
            case .easy:
                self.maxMoves = 100
                self.obstacle = 2048
            case .medium:
                self.maxMoves = 50
                self.obstacle = 4096
            }
        } else {
            // 否則依目前難易度重置障礙初始值
            switch self.difficulty {
            case .easy:
                self.obstacle = 2048
            case .medium:
                self.obstacle = 4096
            }
        }
        
        moveCount = 0
        gameOver = false
        message = ""
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
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
        let arr = line.filter { $0 != 0 }
        var result: [Int] = []
        var skip = false
        for i in 0..<arr.count {
            if skip {
                skip = false
                continue
            }
            if i < arr.count - 1 && arr[i] == arr[i+1] {
                // 合併：例如 2 + 2 = 4
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

    
    // 每次滑動都扣除一步，不論棋盤是否有變化
    func move(_ direction: SwipeDirection) {
        guard !gameOver else { return }
        
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
        // 每次滑動都扣除一步
        moveCount += 1
        addRandomTile()
        checkGameStatus()
    }
    
    func checkGameStatus() {
        if obstacle <= 0 {
            message = NSLocalizedString("msg_you_win", comment: "Victory message when obstacle is cleared")
            gameOver = true
        } else if moveCount >= maxMoves {
            message = NSLocalizedString("msg_moves_exhausted", comment: "Message when moves are exhausted")
            gameOver = true
        }
        // 同步更新障礙所在位置
        board[size-1][size-1] = obstacle
    }
    
    // MARK: - 各方向移動邏輯
    func moveLeft() {
        for r in 0..<size {
            if r == size-1 {
                var segment = Array(board[r][0..<size-1])
                segment = mergeLine(segment)
                for c in 0..<size-1 {
                    board[r][c] = segment[c]
                }
            } else {
                board[r] = mergeLine(board[r])
            }
        }
    }
    
    func moveRight() {
        for r in 0..<size {
            // 如果不是最下面那一行，照一般 4×4 邏輯處理
            if r != size - 1 {
                var row = board[r]
                row.reverse()
                row = mergeLine(row)
                row.reverse()
                board[r] = row
            }
            // ★ 最下面一行 (r=3) ★
            else {
                // 只取左邊三格 (c=0..2)，排除障礙所在的 (3,3)
                var rowSegment = Array(board[r][0..<(size-1)]) // (3,0), (3,1), (3,2)
                
                // 反轉 → 合併 → 再反轉
                rowSegment.reverse()
                rowSegment = mergeLine(rowSegment)
                rowSegment.reverse()
                
                // 如果合併完最後一格 != 0，代表它想再「往右」進入障礙
                if let A = rowSegment.last, A != 0 {
                    if obstacle > A {
                        obstacle -= A * A
                        rowSegment[rowSegment.count - 1] = 0
                    }
                    if obstacle <= 0 {
                        message = NSLocalizedString("msg_obstacle_cleared", comment: "Message when obstacle is cleared")
                        gameOver = true
                    }
                }
                
                // 回填前 3 格
                for c in 0..<(size-1) {
                    board[r][c] = rowSegment[c]
                }
                // 最右邊 (3,3) 永遠是障礙
                board[r][size-1] = obstacle
            }
        }
    }

    
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
    
    
    func moveDown() {
        for c in 0..<size {
            // 如果不是最右一欄，照一般 4×4 邏輯處理
            if c != size - 1 {
                var col = [Int]()
                for r in 0..<size {
                    col.append(board[r][c])
                }
                // 反轉 → 合併 → 再反轉，模擬「往下」移動
                col.reverse()
                col = mergeLine(col)
                col.reverse()
                
                // 回填到原本的 board
                for r in 0..<size {
                    board[r][c] = col[r]
                }
            }
            // ★ 最右一欄 (c=3) ★
            else {
                // 只取上面三格 (r=0..2)，排除障礙所在的最底 row=3
                var col = [Int]()
                for r in 0..<(size-1) {
                    col.append(board[r][c])  // 收集 (0,3)、(1,3)、(2,3)
                }
                // 反轉 → 合併 → 再反轉
                col.reverse()
                col = mergeLine(col)
                col.reverse()
                
                // 如果合併完最後一格 != 0，代表它想再「往下」進入障礙
                if let A = col.last, A != 0 {
                    if obstacle > A {
                        obstacle -= A * A
                        col[col.count - 1] = 0  // 把那格清空
                    }
                    // 如果障礙扣到 0 或以下 → 勝利
                    if obstacle <= 0 {
                        message = NSLocalizedString("msg_obstacle_cleared", comment: "Message when the obstacle has been cleared")
                        gameOver = true
                    }
                }
                
                // 把合併後的結果放回前 3 格
                for r in 0..<(size-1) {
                    board[r][c] = col[r]
                }
                // 最下面 (3,3) 永遠是障礙
                board[size-1][c] = obstacle
            }
        }
    }

}

// MARK: - UI Components

// 單一方塊視圖，依據數值顯示不同背景與文字顏色，障礙方塊則特別標示
struct TileView: View {
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
            // 空格
            return Color(red: 205/255, green: 193/255, blue: 180/255)
        }
        return tileBackground(for: value)
    }
    
    func tileBackground(for number: Int) -> Color {
        switch number {
        case 2:     return Color(red: 238/255, green: 228/255, blue: 218/255)
        case 4:     return Color(red: 237/255, green: 224/255, blue: 200/255)
        case 8:     return Color(red: 242/255, green: 177/255, blue: 121/255)
        case 16:    return Color(red: 245/255, green: 149/255, blue: 99/255)
        case 32:    return Color(red: 246/255, green: 124/255, blue: 95/255)
        case 64:    return Color(red: 246/255, green: 94/255, blue: 59/255)
        case 128:   return Color(red: 237/255, green: 207/255, blue: 114/255)
        case 256:   return Color(red: 237/255, green: 204/255, blue: 97/255)
        case 512:   return Color(red: 237/255, green: 200/255, blue: 80/255)
        case 1024:  return Color(red: 237/255, green: 197/255, blue: 63/255)
        case 2048:  return Color(red: 237/255, green: 194/255, blue: 46/255)
        default:    return Color.black
        }
    }
    
    var textColor: Color {
        if value == 2 || value == 4 {
            return Color(red: 119/255, green: 110/255, blue: 101/255)
        }
        return Color.white
    }
}

// 棋盤視圖，模擬官方版 2048 的棋盤外框與格子間距
struct GameBoardView: View {
    @ObservedObject var game: Game2048Obstacle
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<game.size, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(0..<game.size, id: \.self) { c in
                        let isObstacle = (r == game.size - 1 && c == game.size - 1)
                        TileView(value: isObstacle ? game.obstacle : game.board[r][c],
                                 isObstacle: isObstacle)
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

// 標題與狀態顯示區，顯示「剩餘步數」與「剩餘障礙」
struct GameHeaderView: View {
    let remainingMoves: Int
    let remainingObstacle: Int
    
    var body: some View {
        HStack {
            Text("title_2048")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(Color(red: 119/255, green: 110/255, blue: 101/255))
            Spacer()
            VStack(alignment: .trailing) {
                Text("label_remaining_moves")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("\(remainingMoves)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(Color(red: 187/255, green: 173/255, blue: 160/255))
            .cornerRadius(6)
            VStack(alignment: .trailing) {
                Text("label_remaining_obstacle")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("\(remainingObstacle)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(Color(red: 187/255, green: 173/255, blue: 160/255))
            .cornerRadius(6)
        }
        .padding(.horizontal)
    }
}

// 主遊戲畫面，包含難易度選擇、狀態顯示、棋盤、遊戲規則說明與手勢操作
struct GameViewShared: View {
    @State private var selectedDifficulty: Difficulty = .easy
    @StateObject private var game: Game2048Obstacle = Game2048Obstacle(difficulty: .easy)
    // 新增用於觸發勝利動畫與防止重複播放音效的 state
    @State private var animateVictory: Bool = false
    @State private var soundPlayed: Bool = false
    
    var body: some View {
        ZStack {
            Color(red: 250/255, green: 248/255, blue: 239/255)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                // 難易度選擇
                Picker("label_difficulty", selection: $selectedDifficulty) {
                    ForEach(Difficulty.allCases) { difficulty in
                        difficulty.label.tag(difficulty)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                // 切換難易度時，建立新的遊戲實例
                .onChange(of: selectedDifficulty) { newDifficulty in
                    // resetGame() 中處理難易度相關的邏輯
                    game.resetGame(newDifficulty: newDifficulty) // 或者重新指派一個新實例
                    // 重設動畫與音效播放旗標
                    animateVictory = false
                    soundPlayed = false
                }
                
                // 傳入剩餘步數 (maxMoves - moveCount) 與障礙數值
                GameHeaderView(remainingMoves: game.maxMoves - game.moveCount,
                               remainingObstacle: game.obstacle)
                
                // 遊戲規則說明 (包含合併示例)
                Text("rules_classic_combined")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                GameBoardView(game: game)
                Spacer()
                if game.gameOver {
                    Text(game.message)
                        .font(.title)
                        .foregroundColor(.red)
                        .padding()
                }
                Button(action: {
                    withAnimation {
                        game.resetGame()
                        // 重設動畫與音效播放旗標
                        animateVictory = false
                        soundPlayed = false
                    }
                }) {
                    Text("btn_new_game")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 143/255, green: 122/255, blue: 102/255))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
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
            
            // 當遊戲結束且勝利時顯示勝利動畫覆蓋層
            if game.gameOver && (
                game.message == NSLocalizedString("msg_you_win", comment: "Victory message") ||
                game.message == NSLocalizedString("msg_obstacle_cleared", comment: "Obstacle cleared victory message")
            ) {
                VictoryOverlayView(animate: $animateVictory)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        if !soundPlayed {
                            SoundManager.shared.playVictorySound()
                            soundPlayed = true
                        }
                    }
            }
        }
        
        BannerAdView(adUnitID: "ca-app-pub-9275380963550837/8710922047")
            .frame(height: 50)
    }
}

// MARK: - 預覽
struct GameViewShared_Previews: PreviewProvider {
    static var previews: some View {
        GameViewShared()
    }
}
