//
//  TimeControlPreset.swift
//  ChessClock
//

import Foundation

struct TimeControlPreset {
    let name: String
    let minutes: Int
    let increment: Int
    
    var initialSeconds: TimeInterval {
        TimeInterval(minutes * 60)
    }
} 