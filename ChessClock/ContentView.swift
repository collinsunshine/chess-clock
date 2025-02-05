//
//  ContentView.swift
//  ChessClock
//
//  Created by Collin Sansom on 1/9/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    
    @State private var showingPresetPicker = false
    @State private var showingSettingsSheet = false
    @State private var showMoveCounter = true
    @State private var showingResetConfirmation = false
    @State private var showingPresetChangeConfirmation = false
    @State private var pendingPresetIndex: Int?
    @State private var player1Frame: CGRect = .zero
    @State private var player2Frame: CGRect = .zero
    @State private var maskFrame: CGRect = .zero
    @State private var isAnimatingMask = false
    @State private var maskStartFrame: CGRect = .zero
    
    @Environment(\.scenePhase) private var scenePhase
    
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
                .opacity(viewModel.maskOpacity)
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
                        if viewModel.activePlayer == nil || viewModel.activePlayer == 2 {
                            handlePlayerSwitch(to: 1, fromFrame: player2Frame, toFrame: player1Frame)
                        }
                    }) {
                        VStack {
                            Spacer()
                            TimeDisplay(
                                seconds: viewModel.player2Time,
                                isActive: viewModel.activePlayer == 2,
                                turnCount: viewModel.player2Turns,
                                showMoveCounter: showMoveCounter
                            )
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            Color(.quaternarySystemFill)
                                .opacity(viewModel.isGameInProgress ? 0 : 1)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.isGameInProgress)
                        )
                        .cornerRadius(40)
                    }
                    .rotationEffect(.degrees(180))
                    .disabled(viewModel.isGameOver || viewModel.activePlayer == 1 || 
                             (viewModel.activePlayer == nil && viewModel.lastActivePlayer != nil))
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
                            Text(viewModel.currentPreset.name)
                                .font(.headline)
                                .foregroundColor(viewModel.activePlayer != nil ? .secondary : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color(.quaternarySystemFill))
                                .cornerRadius(40)
                        }
                        .disabled(viewModel.activePlayer != nil)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            if viewModel.isGameInProgress && viewModel.activePlayer == nil {
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
                            
                            if viewModel.activePlayer == nil {
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
                            
                            if viewModel.isGameInProgress {
                                Button(action: {
                                    if viewModel.activePlayer == nil {
                                        handlePlayerSwitch(to: viewModel.lastActivePlayer ?? 1, fromFrame: player2Frame, toFrame: player1Frame)
                                    } else {
                                        viewModel.pauseGame()
                                    }
                                }) {
                                    Image(systemName: viewModel.activePlayer == nil ? "play.fill" : "pause.fill")
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
                        presets: viewModel.presets,
                        selectedIndex: viewModel.selectedPresetIndex,
                        isGameInProgress: viewModel.isGameInProgress,
                        onSelect: { index in
                            if viewModel.isGameInProgress {
                                pendingPresetIndex = index
                                showingPresetPicker = false
                                showingPresetChangeConfirmation = true
                            } else {
                                viewModel.selectedPresetIndex = index
                                showingPresetPicker = false
                                viewModel.resetGame()
                            }
                        }
                    )
                }
                
                // Player 1 clock
                GeometryReader { geometry in
                    Button(action: {
                        if viewModel.activePlayer == nil || viewModel.activePlayer == 1 {
                            handlePlayerSwitch(to: 2, fromFrame: player1Frame, toFrame: player2Frame)
                        }
                    }) {
                        VStack {
                            Spacer()
                            TimeDisplay(
                                seconds: viewModel.player1Time,
                                isActive: viewModel.activePlayer == 1,
                                turnCount: viewModel.player1Turns,
                                showMoveCounter: showMoveCounter
                            )
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            Color(.quaternarySystemFill)
                                .opacity(viewModel.isGameInProgress ? 0 : 1)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.isGameInProgress)
                        )
                        .cornerRadius(40)
                    }
                    .disabled(viewModel.isGameOver || viewModel.activePlayer == 2 || 
                             (viewModel.activePlayer == nil && viewModel.lastActivePlayer != nil))
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
            if newPhase == .background && viewModel.activePlayer != nil {
                viewModel.pauseGame()
            }
        }
        .onChange(of: viewModel.isGameInProgress) { oldValue, newValue in
            UIApplication.shared.isIdleTimerDisabled = newValue
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .alert(isPresented: $viewModel.isGameOver) {
            Alert(
                title: Text("Game Over"),
                message: Text("Player \(viewModel.player1Time <= 0 ? "2" : "1") wins!"),
                dismissButton: .default(Text("New Game")) {
                    viewModel.resetGame()
                }
            )
        }
        .alert("Confirm Reset", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetGame()
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
                    viewModel.selectedPresetIndex = newIndex
                    viewModel.resetGame()
                }
                pendingPresetIndex = nil
            }
        } message: {
            Text("Changing the time control will reset the current game. Are you sure?")
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView(
                isSoundEnabled: $viewModel.isSoundEnabled,
                showMoveCounter: $showMoveCounter
            )
        }
    }
    
    private func handlePlayerSwitch(to player: Int, fromFrame: CGRect, toFrame: CGRect) {
        // If starting from a paused state, just switch players
        if viewModel.activePlayer == nil && viewModel.lastActivePlayer != nil {
            viewModel.switchToPlayer(player)
            return
        }
        
        // Handle animation for new game start and player switches
        maskFrame = fromFrame
        
        withAnimation(.easeInOut(duration: 0.3)) {
            maskFrame = toFrame
            isAnimatingMask = true
        }
        
        viewModel.switchToPlayer(player)
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
                .overlay {
                    Text(timeString)
                        .font(.system(size: 90, design: .default))
                        .fontWeight(.regular)
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .opacity(isActive ? 1 : 0)
                }
                .foregroundColor(.secondary)
            
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
