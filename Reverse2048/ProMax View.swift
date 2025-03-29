//
//  ProMax View.swift
//  Reverse2048
//
//  Created by chang chiawei on 2025-03-28.
//

import SwiftUI
import AVFoundation  // 新增 AVFoundation 用於播放音效

// MARK: - 音效管理器
class SoundManager {
    static let shared = SoundManager()
    var audioPlayer: AVAudioPlayer?
    
    func playVictorySound() {
        // 請將勝利音效檔案命名為 "victory.mp3" 並加入專案中
        guard let url = Bundle.main.url(forResource: "win", withExtension: "mp3") else {
            print("Victory sound file not found")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing victory sound: \(error.localizedDescription)")
        }
    }
}



class Game2048ObstacleProMAX: ObservableObject {
    @Published var board: [[Int]]
    @Published var moveCount: Int = 0
    @Published var gameOver: Bool = false
    @Published var message: String = ""
    // 障礙值獨立記錄，不參與合併
    @Published var obstacle: Int
    
    let size = 4
    var maxMoves: Int
    var difficulty: Difficulty
    
    init(difficulty: Difficulty = .easy) {
        self.difficulty = difficulty
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
    
    // 若 newDifficulty 不為 nil，則依照新難易度重置相關參數
    func resetGame(newDifficulty: Difficulty? = nil) {
        if let diff = newDifficulty {
            self.difficulty = diff
            switch diff {
            case .easy:
                self.maxMoves = 50
                self.obstacle = 9999
            case .medium:
                self.maxMoves = 150
                self.obstacle = 999999
            }
        } else {
            switch self.difficulty {
            case .easy:
                self.obstacle = 9999
            case .medium:
                self.obstacle = 999999
            }
        }
        moveCount = 0
        gameOver = false
        message = ""
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        addRandomTile()
        addRandomTile()
        // 固定障礙：右下角 (不參與合併邏輯)
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
    
    // 新版合併函數，依照 HTML 邏輯實作：
    // 若相同 → 兩數相乘 (即 A 與 A 合併為 A²)
    // 若不同 → 兩數差的絕對值 (即 |A - B|)
    func mergeLine(_ line: [Int]) -> [Int] {
        let arr = line.filter { $0 != 0 }
        var merged: [Int] = []
        var skip = false
        for i in 0..<arr.count {
            if skip {
                skip = false
                continue
            }
            if i < arr.count - 1 {
                if arr[i] == arr[i+1] {
                    merged.append(arr[i] * arr[i])
                } else {
                    merged.append(abs(arr[i] - arr[i+1]))
                }
                skip = true
            } else {
                merged.append(arr[i])
            }
        }
        while merged.count < line.count {
            merged.append(0)
        }
        return merged
    }
    
    // 每次滑動若有變化，扣除一步、生成新方塊並檢查遊戲狀態
    func move(_ direction: SwipeDirection) {
        guard !gameOver else { return }
        let boardBefore = board
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
        if board != boardBefore {
            moveCount += 1
            addRandomTile()
            checkGameStatus()
        }
    }
    
    func checkGameStatus() {
        if obstacle <= 0 {
            message = NSLocalizedString("msg_obstacle_cleared", comment: "Obstacle cleared message")
            gameOver = true
        } else if moveCount >= maxMoves {
            message = NSLocalizedString("msg_moves_exhausted", comment: "Out of moves message")
            gameOver = true
        }
        // 確保障礙格數值同步
        board[size-1][size-1] = obstacle
    }

    
    // MARK: - 各方向移動邏輯 (參照 HTML 版本)
    // 左移：若底部行，僅處理前 3 格，保持障礙不變
    func moveLeft() {
        for r in 0..<size {
            if r == size-1 {
                var segment = Array(board[r][0..<size-1])
                segment = mergeLine(segment)
                for c in 0..<size-1 {
                    board[r][c] = segment[c]
                }
                board[r][size-1] = obstacle
            } else {
                board[r] = mergeLine(board[r])
            }
        }
    }
    
    // 右移：方向反轉處理，但不觸發障礙合併
    func moveRight() {
        for r in 0..<size {
            if r == size-1 {
                // 取出底部行的前 3 格
                var segment = Array(board[r][0..<size-1])
                // 反轉 → 合併 → 再反轉
                segment.reverse()
                segment = mergeLine(segment)
                segment.reverse()
                
                // 如果 segment 最右邊 (segment.last) 還有數字，表示它想「往右」進入障礙
                if let lastValue = segment.last, lastValue != 0 {
                    if obstacle > lastValue {
                        obstacle -= lastValue * lastValue
                        segment[segment.count - 1] = 0
                        if obstacle <= 0 {
                            message = NSLocalizedString("msg_obstacle_cleared", comment: "Obstacle cleared message")
                            gameOver = true
                        }
                    }
                }

                
                // 更新回到底部那一行
                for c in 0..<size-1 {
                    board[r][c] = segment[c]
                }
                // 最右邊的格子依然是障礙
                board[r][size-1] = obstacle
                
            } else {
                // 其他行維持一般合併邏輯
                var row = board[r]
                row.reverse()
                row = mergeLine(row)
                row.reverse()
                board[r] = row
            }
        }
    }

    
    // 上移：處理各列，若最後一列為障礙則排除
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
                board[size-1][c] = obstacle
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
    
    // 下移：僅在最右側（障礙所在列）處進行障礙合併檢查
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
                // 檢查底部數字是否欲移入障礙格
                if let A = col.last, A != 0 {
                    if obstacle > A {
                        obstacle -= A * A
                        col[col.count - 1] = 0
                    }
                    if obstacle <= 0 {
                        message = NSLocalizedString("msg_obstacle_cleared", comment: "Obstacle cleared message")
                        gameOver = true
                    }
                }
                for r in 0..<size-1 {
                    board[r][c] = col[r]
                }
                board[size-1][c] = obstacle
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

struct TileViewProMax: View {
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

// MARK: - 勝利動畫覆蓋層
struct VictoryOverlayView: View {
    @Binding var animate: Bool

    var body: some View {
        Text("🎉 Victory! 🎉")
            .font(.largeTitle)
            .fontWeight(.heavy)
            .foregroundColor(.green)
            .scaleEffect(animate ? 1.2 : 0.8)
            .opacity(animate ? 1.0 : 0.5)
            .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
            .onAppear {
                animate = true
            }
    }
}

struct GameBoardViewProMax: View {
    @ObservedObject var game: Game2048ObstacleProMAX
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<game.size, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(0..<game.size, id: \.self) { c in
                        let isObstacle = (r == game.size - 1 && c == game.size - 1)
                        TileViewProMax(value: isObstacle ? game.obstacle : game.board[r][c],
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

struct GameHeaderViewProMax: View {
    let remainingMoves: Int
    let remainingObstacle: Int
    
    var body: some View {
        HStack {
            Text("2048")
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

struct GameViewSharedProMax: View {
    @State private var selectedDifficulty: Difficulty = .easy
    @StateObject private var game: Game2048ObstacleProMAX = Game2048ObstacleProMAX(difficulty: .easy)
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
                .onChange(of: selectedDifficulty) { newDifficulty in
                    game.resetGame(newDifficulty: newDifficulty)
                    // 重設動畫與音效播放旗標
                    animateVictory = false
                    soundPlayed = false
                }
                
                GameHeaderViewProMax(remainingMoves: game.maxMoves - game.moveCount,
                                     remainingObstacle: game.obstacle)
                
                Text("rules_combinedProMax")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                GameBoardViewProMax(game: game)
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
            if game.gameOver &&
                (game.message == NSLocalizedString("msg_you_win", comment: "Victory message") ||
                 game.message == NSLocalizedString("msg_obstacle_cleared", comment: "Obstacle cleared message")) {
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
    }
}

struct GameViewSharedProMax_Previews: PreviewProvider {
    static var previews: some View {
        GameViewSharedProMax()
    }
}
