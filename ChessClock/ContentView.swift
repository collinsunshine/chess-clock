//
//  ContentView.swift
//  ChessClock
//
//  Created by Collin Sansom on 1/9/25.
//

import SwiftUI
import AVFoundation

struct TimeControlPreset {
    let name: String
    let minutes: Int
    let increment: Int
    
    var initialSeconds: TimeInterval {
        TimeInterval(minutes * 60)
    }
}

struct ContentView: View {
    private let presets = [
        TimeControlPreset(name: "Bullet", minutes: 1, increment: 0),
        TimeControlPreset(name: "Bullet", minutes: 1, increment: 1),
        TimeControlPreset(name: "Bullet", minutes: 2, increment: 1),
        TimeControlPreset(name: "Blitz", minutes: 3, increment: 0),
        TimeControlPreset(name: "Blitz", minutes: 3, increment: 2),
        TimeControlPreset(name: "Blitz", minutes: 5, increment: 0),
        TimeControlPreset(name: "Blitz", minutes: 5, increment: 3),
        TimeControlPreset(name: "Rapid", minutes: 10, increment: 0),
        TimeControlPreset(name: "Rapid", minutes: 10, increment: 5),
        TimeControlPreset(name: "Rapid", minutes: 15, increment: 10),
        TimeControlPreset(name: "Classical", minutes: 30, increment: 0),
        TimeControlPreset(name: "Classical", minutes: 30, increment: 10),
        TimeControlPreset(name: "Classical", minutes: 60, increment: 30)
    ]
    
    @State private var selectedPresetIndex = 2
    @State private var player1Time: TimeInterval = 600
    @State private var player2Time: TimeInterval = 600
    @State private var timer: Timer?
    @State private var activePlayer: Int? = nil
    @State private var isGameOver = false
    @State private var showingPresetPicker = false
    @State private var isSoundEnabled = true
    
    private var audioPlayer1: AVAudioPlayer?
    private var audioPlayer2: AVAudioPlayer?
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        if let soundURL1 = Bundle.main.url(forResource: "click1", withExtension: "wav") {
            do {
                audioPlayer1 = try AVAudioPlayer(contentsOf: soundURL1)
                audioPlayer1?.volume = 1.0
                audioPlayer1?.numberOfLoops = 0
                audioPlayer1?.prepareToPlay()
            } catch {
                print("Error loading sound 1: \(error.localizedDescription)")
            }
        }
        
        if let soundURL2 = Bundle.main.url(forResource: "click2", withExtension: "wav") {
            do {
                audioPlayer2 = try AVAudioPlayer(contentsOf: soundURL2)
                audioPlayer2?.volume = 1.0
                audioPlayer2?.numberOfLoops = 0
                audioPlayer2?.prepareToPlay()
            } catch {
                print("Error loading sound 2: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        VStack {
            // Player 2 clock (rotated for better UX)
            Button(action: {
                if activePlayer == nil || activePlayer == 2 {
                    switchToPlayer(1)
                }
            }) {
                TimeDisplay(seconds: player2Time, isActive: activePlayer == 2)
            }
            .rotationEffect(.degrees(180))
            .disabled(isGameOver || activePlayer == 1)
            
            // Center controls
            VStack {
                HStack {
                    Button(action: {
                        showingPresetPicker = true
                    }) {
                        VStack {
                            Text("\(presets[selectedPresetIndex].name)")
                                .font(.headline)
                            Text("\(presets[selectedPresetIndex].minutes)+\(presets[selectedPresetIndex].increment)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .disabled(activePlayer != nil)
                    
                    Button(action: {
                        isSoundEnabled.toggle()
                    }) {
                        Image(systemName: isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundColor(isSoundEnabled ? .blue : .gray)
                            .font(.system(size: 20))
                    }
                    .padding()
                    
                    Button("Reset") {
                        resetGame()
                    }
                    .padding()
                    
                    Button(activePlayer == nil ? "Start" : "Pause") {
                        if activePlayer == nil {
                            switchToPlayer(1)
                        } else {
                            pauseGame()
                        }
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showingPresetPicker) {
                NavigationView {
                    List {
                        ForEach(0..<presets.count, id: \.self) { index in
                            Button(action: {
                                selectedPresetIndex = index
                                showingPresetPicker = false
                                resetGame()
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(presets[index].name)
                                            .font(.headline)
                                        Text("\(presets[index].minutes) minutes + \(presets[index].increment) seconds")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if index == selectedPresetIndex {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .navigationTitle("Time Controls")
                    .navigationBarItems(trailing: Button("Done") {
                        showingPresetPicker = false
                    })
                }
            }
            
            // Player 1 clock
            Button(action: {
                if activePlayer == nil || activePlayer == 1 {
                    switchToPlayer(2)
                }
            }) {
                TimeDisplay(seconds: player1Time, isActive: activePlayer == 1)
            }
            .disabled(isGameOver || activePlayer == 2)
        }
        .alert(isPresented: $isGameOver) {
            Alert(
                title: Text("Game Over"),
                message: Text("Player \(player1Time <= 0 ? "2" : "1") wins!"),
                dismissButton: .default(Text("New Game")) {
                    resetGame()
                }
            )
        }
    }
    
    private func switchToPlayer(_ player: Int) {
        playFeedback(forPlayer: player)
        
        let increment = TimeInterval(presets[selectedPresetIndex].increment)
        if let previousPlayer = activePlayer {
            if previousPlayer == 1 {
                player1Time += increment
            } else {
                player2Time += increment
            }
        }
        
        activePlayer = player
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if player == 1 {
                player1Time -= 0.1
                if player1Time <= 0 {
                    endGame()
                }
            } else {
                player2Time -= 0.1
                if player2Time <= 0 {
                    endGame()
                }
            }
        }
    }
    
    private func pauseGame() {
        timer?.invalidate()
        timer = nil
        activePlayer = nil
    }
    
    private func resetGame() {
        timer?.invalidate()
        timer = nil
        let preset = presets[selectedPresetIndex]
        player1Time = preset.initialSeconds
        player2Time = preset.initialSeconds
        activePlayer = nil
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
            if let player = audioPlayer1 {
                player.currentTime = 0
                player.play()
            }
        } else {
            if let player = audioPlayer2 {
                player.currentTime = 0
                player.play()
            }
        }
    }
}

struct TimeDisplay: View {
    let seconds: TimeInterval
    let isActive: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            
            Text(timeString)
                .font(.system(size: 60, design: .monospaced))
                .foregroundColor(seconds <= 30 ? .red : .primary)
        }
        .padding()
    }
    
    private var timeString: String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    ContentView()
}
