//
//  ReverseView.swift
//  Reverse2048
//
//  Created by chang chiawei on 2025-03-29.
//

import SwiftUI




// MARK: - 遊戲邏輯 (Reverse 模式) with Difficulty
class Game2048Reverse: ObservableObject {
    @Published var board: [[Int]]
    @Published var gameOver: Bool = false
    @Published var message: String = ""
    
    // 記錄是否達成勝利條件（merge 產生 0）
    var winAchieved: Bool = false
    
    // 新增難易度屬性：簡單（easy）使用 2048；中等（medium）使用 4098
    var difficulty: Difficulty = .easy
    
    let size = 4
    
    init(difficulty: Difficulty = .easy) {
        self.difficulty = difficulty
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        resetGame()
    }
    
    // 提供可選參數以變更難易度
    func resetGame(newDifficulty: Difficulty? = nil) {
        if let diff = newDifficulty {
            self.difficulty = diff
        }
        gameOver = false
        message = ""
        winAchieved = false
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        addRandomTile()
        addRandomTile()
    }
    
    // 根據難易度決定初始生成的方塊數值：
    // easy → 2048；medium → 4098
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
            board[cell.0][cell.1] = (difficulty == .easy ? 2048 : 4098)
        }
    }
    
    // 合併邏輯：相同的數字合併後除以2 (例如 2048 + 2048 -> 1024)
    // 當合併兩個 1 時，1/2 會產生 0，此時觸發勝利
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
                let merged = arr[i] / 2
                if arr[i] == 1 {
                    winAchieved = true
                }
                result.append(merged)
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
    
    // 移動操作：滑動後加入新方塊並檢查遊戲狀態
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
    
    // 檢查遊戲狀態：如果沒有空格且無法合併則遊戲結束，
    // 或者只要有一次合併產生 0 則勝利
    func checkGameStatus() {
        if !board.flatMap({ $0 }).contains(0) && !hasMoves() {
            gameOver = true
            message = NSLocalizedString("msg_game_over", comment: "Game over message")
        }
        if winAchieved {
            gameOver = true
            message = NSLocalizedString("msg_you_win", comment: "Victory message")
            return
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

// 單一方塊視圖 (Reverse 模式)
struct TileViewReverse: View {
    let value: Int
    let isObstacle: Bool = false // Reverse 模式不使用障礙
    
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
        if value == 0 {
            return Color(red: 205/255, green: 193/255, blue: 180/255)
        }
        return tileBackground(for: value)
    }
    
    func tileBackground(for number: Int) -> Color {
        // 這裡僅示範 2048 與 4098 兩種顏色，其他數值可依需求擴充
        switch number {
        case 2048: return Color(red: 237/255, green: 194/255, blue: 46/255)
        case 4098: return Color(red: 200/255, green: 150/255, blue: 50/255)
        default:   return Color(red: 238/255, green: 228/255, blue: 218/255)
        }
    }
    
    var textColor: Color {
        if value == 2048 || value == 4098 {
            return Color.white
        }
        return Color.black
    }
}

// 棋盤視圖
struct GameBoardReverseView: View {
    @ObservedObject var game: Game2048Reverse
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<game.size, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(0..<game.size, id: \.self) { c in
                        TileViewReverse(value: game.board[r][c])
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

// MARK: - 主遊戲畫面 (參考 Classic UI 版型)
struct ReverseGameViewShared: View {
    @State private var selectedDifficulty: Difficulty = .easy
    @StateObject private var game = Game2048Reverse(difficulty: .easy)
    
    // 用於觸發勝利動畫與防止重複播放音效的 state
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
                .onChange(of: selectedDifficulty) { newDifficulty in
                    game.resetGame(newDifficulty: newDifficulty)
                    animateVictory = false
                    soundPlayed = false
                }
                Spacer()
                // 標題
                Text("title")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(Color(red: 119/255, green: 110/255, blue: 101/255))
                
                Spacer()
                GameBoardReverseView(game: game)
                Spacer()
                
                if game.gameOver {
                    Text(game.message)
                        .font(.title)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: {
                    // 設定廣告關閉後的回呼：重置遊戲
                    AdManager.shared.adDidDismissFullScreenContentCallback = {
                        game.resetGame()
                        animateVictory = false
                        soundPlayed = false
                    }
                    
                    // 取得當前的 rootViewController
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let root = windowScene.windows.first?.rootViewController {
                        AdManager.shared.showInterstitial(from: root)
                    } else {
                        // 若取得失敗則直接重置遊戲
                        game.resetGame()
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
            // 手勢操作
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
            
            // 勝利動畫覆蓋層（當遊戲結束且勝利時顯示）
            if game.gameOver && game.message == NSLocalizedString("msg_you_win", comment: "Victory message") {
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
        }.onAppear {
            // 載入第一支插頁廣告
            AdManager.shared.loadInterstitial()
        }
        
        // Banner 廣告（假設 BannerAdView 已定義）
        BannerAdView(adUnitID: "ca-app-pub-9275380963550837/8710922047")
            .frame(height: 50)
    }
}



// MARK: - 預覽
struct ReverseGameViewShared_Previews: PreviewProvider {
    static var previews: some View {
        ReverseGameViewShared()
    }
}
