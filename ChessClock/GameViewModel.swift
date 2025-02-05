import SwiftUI
import AVFoundation

class GameViewModel: ObservableObject {
    let presets = [
        TimeControlPreset(name: "1 min", minutes: 1, increment: 0),
        TimeControlPreset(name: "1 min | 1 sec", minutes: 1, increment: 1),
        TimeControlPreset(name: "2 min | 1 sec", minutes: 2, increment: 1),
        TimeControlPreset(name: "3 min", minutes: 3, increment: 0),
        TimeControlPreset(name: "3 min | 2 sec", minutes: 3, increment: 2),
        TimeControlPreset(name: "5 min", minutes: 5, increment: 0),
        TimeControlPreset(name: "5 min | 3 sec", minutes: 5, increment: 3),
        TimeControlPreset(name: "10 min", minutes: 10, increment: 0),
        TimeControlPreset(name: "10 min | 5 sec", minutes: 10, increment: 5),
        TimeControlPreset(name: "15 min | 5 sec", minutes: 15, increment: 5),
        TimeControlPreset(name: "30 min", minutes: 30, increment: 0),
        TimeControlPreset(name: "30 min | 10 sec", minutes: 30, increment: 10),
        TimeControlPreset(name: "60 min | 30 sec", minutes: 60, increment: 30)
    ]
    
    @Published var selectedPresetIndex = 9
    @Published var player1Time: TimeInterval = 900
    @Published var player2Time: TimeInterval = 900
    @Published var activePlayer: Int? = nil
    @Published var isGameOver = false
    @Published var player1Turns = 0
    @Published var player2Turns = 0
    @Published var lastActivePlayer: Int? = nil
    @Published var maskOpacity: Double = 1.0
    
    private var timer: Timer?
    private var audioPlayer1: AVAudioPlayer?
    private var audioPlayer2: AVAudioPlayer?
    
    var isSoundEnabled = true
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        if let soundURL1 = Bundle.main.url(forResource: "click1", withExtension: "wav") {
            audioPlayer1 = try? AVAudioPlayer(contentsOf: soundURL1)
            audioPlayer1?.volume = 1.0
            audioPlayer1?.numberOfLoops = 0
            audioPlayer1?.prepareToPlay()
        }
        
        if let soundURL2 = Bundle.main.url(forResource: "click2", withExtension: "wav") {
            audioPlayer2 = try? AVAudioPlayer(contentsOf: soundURL2)
            audioPlayer2?.volume = 1.0
            audioPlayer2?.numberOfLoops = 0
            audioPlayer2?.prepareToPlay()
        }
    }
    
    var currentPreset: TimeControlPreset {
        presets[selectedPresetIndex]
    }
    
    var isGameInProgress: Bool {
        player1Time != currentPreset.initialSeconds || 
        player2Time != currentPreset.initialSeconds
    }
    
    func switchToPlayer(_ player: Int) {
        playFeedback(forPlayer: player)
        
        let increment = TimeInterval(currentPreset.increment)
        if let previousPlayer = activePlayer {
            if previousPlayer == 1 {
                player1Time += increment
                player1Turns += 1
            } else {
                player2Time += increment
                player2Turns += 1
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            activePlayer = player
            maskOpacity = 1.0
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if player == 1 {
                self.player1Time -= 0.1
                if self.player1Time <= 0 {
                    self.endGame()
                }
            } else {
                self.player2Time -= 0.1
                if self.player2Time <= 0 {
                    self.endGame()
                }
            }
        }
        
        lastActivePlayer = player
    }
    
    func pauseGame() {
        lastActivePlayer = activePlayer
        timer?.invalidate()
        timer = nil
        
        withAnimation(.easeInOut(duration: 0.3)) {
            activePlayer = nil
            maskOpacity = 0.2
        }
        
        playFeedback(forPlayer: 1)
    }
    
    func resetGame() {
        timer?.invalidate()
        timer = nil
        player1Time = currentPreset.initialSeconds
        player2Time = currentPreset.initialSeconds
        player1Turns = 0
        player2Turns = 0
        
        withAnimation(.easeInOut(duration: 0.3)) {
            activePlayer = nil
            maskOpacity = 0.0
        }
        
        lastActivePlayer = nil
        isGameOver = false
    }
    
    private func endGame() {
        timer?.invalidate()
        timer = nil
        isGameOver = true
    }
    
    private func playFeedback(forPlayer player: Int) {
        guard isSoundEnabled else { return }
        
        if player == 1 {
            audioPlayer1?.currentTime = 0
            audioPlayer1?.play()
        } else {
            audioPlayer2?.currentTime = 0
            audioPlayer2?.play()
        }
    }
} 