//
//  StateHaptics.swift
//  56sim
//
//  The Sound of the State, felt not heard: stray bullets, T-34 main guns,
//  and tanks rumbling past while you pretend not to exist.
//

import CoreHaptics
import SwiftUI

enum HapticCue {
    case strayBullet
    case t34Firing
    case tankRumble
}

/// Pure builders — testable without hardware. Events plus the pattern-level
/// intensity curve the tank rumble swells and fades through.
enum HapticPatterns {
    static func events(for cue: HapticCue) -> [CHHapticEvent] {
        switch cue {
        case .strayBullet:
            // A single crack from somewhere you hope is far away.
            return [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0),
                    ],
                    relativeTime: 0
                )
            ]
        case .t34Firing:
            // The main gun, then the concussive tail rolling down the street.
            return [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35),
                    ],
                    relativeTime: 0,
                    duration: 0.25
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
                    ],
                    relativeTime: 0.25,
                    duration: 0.6
                ),
            ]
        case .tankRumble:
            // One long continuous growl; the curve does the swell and fade.
            return [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
                    ],
                    relativeTime: 0,
                    duration: 5
                )
            ]
        }
    }

    /// Pattern-level intensity modulation. Only the tanks get a curve.
    static func curves(for cue: HapticCue) -> [CHHapticParameterCurve] {
        guard cue == .tankRumble else { return [] }
        // Approaching, passing, receding: swell and fade over five seconds.
        return [
            CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.1),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 2.5, value: 0.9),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 5, value: 0.1),
                ],
                relativeTime: 0
            )
        ]
    }
}

/// Singleton playback; falls back to impact generators where haptic hardware is absent.
final class StateHaptics: @unchecked Sendable {
    static let shared = StateHaptics()

    private static let mutedKey = "stateHapticsMuted"

    private(set) var muted: Bool
    private lazy var engine: CHHapticEngine? = {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        return try? CHHapticEngine()
    }()

    private init() {
        muted = UserDefaults.standard.bool(forKey: Self.mutedKey)
    }

    /// muted → play() is a no-op. The state hears nothing when silenced.
    func setMuted(_ muted: Bool) {
        self.muted = muted
        UserDefaults.standard.set(muted, forKey: Self.mutedKey)
    }

    func play(_ cue: HapticCue) {
        guard !muted else { return }
        if let engine {
            do {
                let pattern = try CHHapticPattern(
                    events: HapticPatterns.events(for: cue),
                    parameterCurves: HapticPatterns.curves(for: cue)
                )
                let player = try engine.makeAdvancedPlayer(with: pattern)
                try engine.start()
                try player.start(atTime: CHHapticTimeImmediate)
            } catch {
                // Hardware said no; the state pretends it did not happen.
            }
        } else {
            let generator = UIImpactFeedbackGenerator(style: Self.impactStyle(for: cue))
            generator.impactOccurred()
        }
    }

    private static func impactStyle(for cue: HapticCue) -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch cue {
        case .strayBullet: .rigid
        case .t34Firing: .heavy
        case .tankRumble: .soft
        }
    }
}
