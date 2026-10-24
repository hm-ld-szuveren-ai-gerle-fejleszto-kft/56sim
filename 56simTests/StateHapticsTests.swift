//
//  StateHapticsTests.swift
//  56simTests
//
//  The state's sound effects, verified as pure event data — maxed, as the
//  people demanded: three bullets, a three-part T-34 report, and a
//  four-point tank swell at full intensity.
//

import CoreHaptics
import Testing

@testable import _6sim

struct StateHapticsTests {
    private func value(_ event: CHHapticEvent, _ id: CHHapticEvent.ParameterID) -> Float? {
        event.eventParameters.first { $0.parameterID == id }?.value
    }

    @Test("Stray bullet: three full-intensity cracks in quick succession")
    func strayBullet() {
        let events = HapticPatterns.events(for: .strayBullet)
        #expect(events.count == 3)
        #expect(events.allSatisfy { $0.type == .hapticTransient })
        for event in events {
            #expect(value(event, .hapticIntensity) == 1.0)
            #expect(value(event, .hapticSharpness) == 1.0)
            #expect(event.duration == 0.02)
        }
        #expect(events.map(\.relativeTime) == [0, 0.05, 0.10])
        #expect(HapticPatterns.curves(for: .strayBullet).isEmpty)
    }

    @Test("T-34 firing: gun, tail, and the roll of the street")
    func t34Firing() {
        let events = HapticPatterns.events(for: .t34Firing)
        #expect(events.count == 3)
        #expect(events[0].type == .hapticTransient)
        #expect(events[1].type == .hapticTransient)
        #expect(events[2].type == .hapticContinuous)
        #expect(value(events[0], .hapticIntensity) == 1.0)
        #expect(value(events[0], .hapticSharpness) == 1.0)
        #expect(events[0].duration == 0.25)
        #expect(events[0].relativeTime == 0)
        #expect(value(events[1], .hapticIntensity) == 0.9)
        #expect(value(events[1], .hapticSharpness) == 0.6)
        #expect(events[1].duration == 0.7)
        #expect(events[1].relativeTime == 0.05)
        #expect(value(events[2], .hapticIntensity) == 0.85)
        #expect(value(events[2], .hapticSharpness) == 0.3)
        #expect(events[2].duration == 1.0)
        #expect(events[2].relativeTime == 0.15)
        #expect(HapticPatterns.curves(for: .t34Firing).isEmpty)
    }

    @Test("Tank rumble: one continuous growl swollen by a four-point curve")
    func tankRumble() {
        let events = HapticPatterns.events(for: .tankRumble)
        #expect(events.count == 1)
        let event = events[0]
        #expect(event.type == .hapticContinuous)
        #expect(event.duration == 5)
        #expect(value(event, .hapticIntensity) == 1.0)
        #expect(value(event, .hapticSharpness) == 1.0)

        let curves = HapticPatterns.curves(for: .tankRumble)
        #expect(curves.count == 1)
        let curve = curves[0]
        #expect(curve.parameterID == .hapticIntensityControl)
        #expect(curve.controlPoints.count == 4)
        #expect(curve.controlPoints.map(\.value) == [0.4, 1.0, 1.0, 0.4])
        #expect(curve.controlPoints.map(\.relativeTime) == [0, 1, 3.5, 5])
        #expect(
            curve.controlPoints.map(\.value).max() == 1.0, "the state does not murmur")
    }

    @Test("Every trigger reaches the recorder; muted silence is total")
    func recorderSeesEveryCue() {
        let haptics = StateHaptics.shared
        haptics.setMuted(false)
        defer { haptics.recorder = nil }
        var fired: [HapticCue] = []
        haptics.recorder = { fired.append($0) }
        haptics.play(.strayBullet)
        haptics.play(.t34Firing)
        haptics.play(.tankRumble)
        #expect(fired == [.strayBullet, .t34Firing, .tankRumble])

        haptics.setMuted(true)
        haptics.play(.strayBullet)
        #expect(fired.count == 3, "when silenced, the state fires nothing at all")
        haptics.setMuted(false)
    }
}
