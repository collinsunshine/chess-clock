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
    @State private var showingResetConfirmation = false
    @State private var showingPresetChangeConfirmation = false
    @State private var pendingPresetIndex: Int?
    @State private var player1Turns = 0
    @State private var player2Turns = 0
    
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
        VStack(spacing: 0) {
            // Player 2 clock (rotated for better UX)
            Button(action: {
                if activePlayer == nil || activePlayer == 2 {
                    switchToPlayer(1)
                }
            }) {
                VStack {
                    Spacer()
                    TimeDisplay(
                        seconds: player2Time,
                        isActive: activePlayer == 2,
                        showTapToStart: activePlayer == nil,
                        turnCount: player2Turns
                    )
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(activePlayer == 2 ? Color.blue.opacity(0.1) : Color.clear)
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
                    
                    if isGameInProgress {
                        Button(action: {
                            if activePlayer == nil {
                                switchToPlayer(1)
                            } else {
                                pauseGame()
                            }
                        }) {
                            Image(systemName: activePlayer == nil ? "play.fill" : "pause.fill")
                                .font(.system(size: 20))
                        }
                        .padding()
                    }
                    
                    Button(action: {
                        isSoundEnabled.toggle()
                    }) {
                        Image(systemName: isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundColor(isSoundEnabled ? .blue : .gray)
                            .font(.system(size: 20))
                    }
                    .padding()
                    
                    if isGameInProgress && activePlayer == nil {
                        Button(action: {
                            showingResetConfirmation = true
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20))
                        }
                        .padding()
                    }
                }
            }
            .padding(.vertical, 8)
            .sheet(isPresented: $showingPresetPicker) {
                NavigationView {
                    List {
                        ForEach(0..<presets.count, id: \.self) { index in
                            Button(action: {
                                if isGameInProgress {
                                    pendingPresetIndex = index
                                    showingPresetPicker = false
                                    showingPresetChangeConfirmation = true
                                } else {
                                    selectedPresetIndex = index
                                    showingPresetPicker = false
                                    resetGame()
                                }
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
                VStack {
                    Spacer()
                    TimeDisplay(
                        seconds: player1Time,
                        isActive: activePlayer == 1,
                        showTapToStart: activePlayer == nil,
                        turnCount: player1Turns
                    )
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(activePlayer == 1 ? Color.blue.opacity(0.1) : Color.clear)
            }
            .disabled(isGameOver || activePlayer == 2)
        }
        .ignoresSafeArea()
        .alert(isPresented: $isGameOver) {
            Alert(
                title: Text("Game Over"),
                message: Text("Player \(player1Time <= 0 ? "2" : "1") wins!"),
                dismissButton: .default(Text("New Game")) {
                    resetGame()
                }
            )
        }
        .alert("Confirm Reset", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetGame()
            }
        } message: {
            Text("Are you sure you want to reset the timer?")
        }
        .alert("Change Time Control?", isPresented: $showingPresetChangeConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingPresetIndex = nil
            }
            Button("Change", role: .destructive) {
                if let newIndex = pendingPresetIndex {
                    selectedPresetIndex = newIndex
                    resetGame()
                }
                pendingPresetIndex = nil
            }
        } message: {
            Text("Changing the time control will reset the current game. Are you sure?")
        }
    }
    
    private func switchToPlayer(_ player: Int) {
        playFeedback(forPlayer: player)
        
        let increment = TimeInterval(presets[selectedPresetIndex].increment)
        if let previousPlayer = activePlayer {
            if previousPlayer == 1 {
                player1Time += increment
                player1Turns += 1
            } else {
                player2Time += increment
                player2Turns += 1
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
        player1Turns = 0
        player2Turns = 0
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
    
    private var isGameInProgress: Bool {
        let currentPreset = presets[selectedPresetIndex]
        return player1Time != currentPreset.initialSeconds || 
               player2Time != currentPreset.initialSeconds
    }
}

struct TimeDisplay: View {
    let seconds: TimeInterval
    let isActive: Bool
    let showTapToStart: Bool
    let turnCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Text(timeString)
                    .font(.system(size: 60, design: .monospaced))
                    .foregroundColor(seconds <= 30 ? .red : .primary)
                
                HStack {
                    Spacer()
                    Text("Moves: \(turnCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
            
            if showTapToStart {
                Text("Tap to Start")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    private var timeString: String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    ContentView()
}
