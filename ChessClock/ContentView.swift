//
//  ContentView.swift
//  ChessClock
//
//  Created by Collin Sansom on 1/9/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    private let presets = [
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
    
    @State private var selectedPresetIndex = 9
    @State private var player1Time: TimeInterval = 900
    @State private var player2Time: TimeInterval = 900
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
    @State private var showingSettingsSheet = false
    @State private var showMoveCounter = true
    @State private var lastActivePlayer: Int?
    @State private var player1Frame: CGRect = .zero
    @State private var player2Frame: CGRect = .zero
    @State private var maskFrame: CGRect = .zero
    @State private var isAnimatingMask = false
    @State private var maskOpacity: Double = 1.0
    @State private var maskStartFrame: CGRect = .zero
    
    private var audioPlayer1: AVAudioPlayer?
    private var audioPlayer2: AVAudioPlayer?
    
    @Environment(\.scenePhase) private var scenePhase
    
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
        ZStack {
            // Background color (replaces the background when masked)
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            // Background image with mask
            Image("mesh-gradient-bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
                .opacity(maskOpacity)
                .mask(
                    Rectangle()
                        .cornerRadius(40)
                        .frame(
                            width: maskFrame.width,
                            height: maskFrame.height
                        )
                        .position(
                            x: maskFrame.midX,
                            y: maskFrame.midY
                        )
                )
            
            // Existing VStack with clocks and controls
            VStack(spacing: 0) {
                // Player 2 clock (rotated for better UX)
                GeometryReader { geometry in
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
                                turnCount: player2Turns,
                                showMoveCounter: showMoveCounter
                            )
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            Color(.quaternarySystemFill)
                                .opacity(isGameInProgress ? 0 : 1)
                                .animation(.easeInOut(duration: 0.3), value: isGameInProgress)
                        )
                        .cornerRadius(40)
                    }
                    .rotationEffect(.degrees(180))
                    .disabled(isGameOver || activePlayer == 1 || (activePlayer == nil && lastActivePlayer != nil))
                    .onAppear {
                        player2Frame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { oldFrame, newFrame in
                        player2Frame = newFrame
                    }
                }
                
                // Center controls
                VStack {
                    HStack {
                        Button(action: {
                            showingPresetPicker = true
                        }) {
                            Text(presets[selectedPresetIndex].name)
                                .font(.headline)
                                .foregroundColor(activePlayer != nil ? .secondary : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color(.quaternarySystemFill))
                                .cornerRadius(40)
                        }
                        .disabled(activePlayer != nil)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            if isGameInProgress && activePlayer == nil {
                                Button(action: {
                                    showingResetConfirmation = true
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .frame(width: 34, height: 34)
                                        .background(Color(.quaternarySystemFill))
                                        .cornerRadius(17)
                                }
                            }
                            
                            if activePlayer == nil {
                                Button(action: {
                                    showingSettingsSheet = true
                                }) {
                                    Image(systemName: "gear")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .frame(width: 34, height: 34)
                                        .background(Color(.quaternarySystemFill))
                                        .cornerRadius(17)
                                }
                            }
                            
                            if isGameInProgress {
                                Button(action: {
                                    if activePlayer == nil {
                                        switchToPlayer(lastActivePlayer ?? 1)
                                    } else {
                                        pauseGame()
                                    }
                                }) {
                                    Image(systemName: activePlayer == nil ? "play.fill" : "pause.fill")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .frame(width: 34, height: 34)
                                        .background(Color(.quaternarySystemFill))
                                        .cornerRadius(17)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
                .sheet(isPresented: $showingPresetPicker) {
                    TimeControlsView(
                        presets: presets,
                        selectedIndex: selectedPresetIndex,
                        isGameInProgress: isGameInProgress,
                        onSelect: { index in
                            if isGameInProgress {
                                pendingPresetIndex = index
                                showingPresetPicker = false
                                showingPresetChangeConfirmation = true
                            } else {
                                selectedPresetIndex = index
                                showingPresetPicker = false
                                resetGame()
                            }
                        }
                    )
                }
                
                // Player 1 clock
                GeometryReader { geometry in
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
                                turnCount: player1Turns,
                                showMoveCounter: showMoveCounter
                            )
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            Color(.quaternarySystemFill)
                                .opacity(isGameInProgress ? 0 : 1)
                                .animation(.easeInOut(duration: 0.3), value: isGameInProgress)
                        )
                        .cornerRadius(40)
                    }
                    .disabled(isGameOver || activePlayer == 2 || (activePlayer == nil && lastActivePlayer != nil))
                    .onAppear {
                        player1Frame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { oldFrame, newFrame in
                        player1Frame = newFrame
                    }
                }
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background && activePlayer != nil {
                pauseGame()
            }
        }
        .onChange(of: isGameInProgress) { oldValue, newValue in
            UIApplication.shared.isIdleTimerDisabled = newValue
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
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
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView(
                isSoundEnabled: $isSoundEnabled,
                showMoveCounter: $showMoveCounter
            )
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
        
        // If starting from a paused state, just fade in the existing mask
        if activePlayer == nil && lastActivePlayer != nil {
            withAnimation(.easeInOut(duration: 0.3)) {
                activePlayer = player
                maskOpacity = 1.0
            }
        } else {
            // Handle both new game start and player switches
            maskOpacity = activePlayer == nil ? 0.0 : 1.0
            maskFrame = player == 1 ? player2Frame : player1Frame
            
            withAnimation(.easeInOut(duration: 0.3)) {
                activePlayer = player
                maskFrame = player == 1 ? player1Frame : player2Frame
                isAnimatingMask = true
                maskOpacity = 1.0
            }
        }
        
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
        
        lastActivePlayer = player
    }
    
    private func pauseGame() {
        lastActivePlayer = activePlayer
        timer?.invalidate()
        timer = nil
        
        withAnimation(.easeInOut(duration: 0.3)) {
            activePlayer = nil
            isAnimatingMask = true
            maskOpacity = 0.2
        }
        
        playFeedback(forPlayer: 1)
    }
    
    private func resetGame() {
        timer?.invalidate()
        timer = nil
        let preset = presets[selectedPresetIndex]
        player1Time = preset.initialSeconds
        player2Time = preset.initialSeconds
        player1Turns = 0
        player2Turns = 0
        
        // Fade out first
        withAnimation(.easeInOut(duration: 0.3)) {
            activePlayer = nil
            maskOpacity = 0.0
        }
        
        // Reset other properties after fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimatingMask = false
            maskStartFrame = .zero
            maskFrame = .zero
            maskOpacity = 1.0
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
    
    private var targetFrame: CGRect {
        switch activePlayer {
        case 1: return player1Frame
        case 2: return player2Frame
        default: return .zero
        }
    }
}

struct TimeDisplay: View {
    let seconds: TimeInterval
    let isActive: Bool
    let turnCount: Int
    let showMoveCounter: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(timeString)
                .font(.system(size: 90, design: .default))
                .fontWeight(.regular)
                .monospacedDigit()
                .foregroundColor(isActive ? .white : .secondary)
            
            Text(moveCountText)
                .font(.subheadline)
                .foregroundColor(isActive ? .white : .secondary)
                .opacity((showMoveCounter && turnCount > 0) ? 1 : 0)
        }
        .padding(.horizontal)
    }
    
    private var moveCountText: String {
        turnCount == 1 ? "1 Move" : "\(turnCount) Moves"
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
