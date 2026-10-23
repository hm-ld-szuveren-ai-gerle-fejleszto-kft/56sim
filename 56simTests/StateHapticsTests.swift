//
//  StateHapticsTests.swift
//  56simTests
//
//  The state's sound effects, verified as pure event data: transient
//  bullets, a two-part T-34 report, and a five-second tank swell.
//

import CoreHaptics
import Testing

@testable import _6sim

struct StateHapticsTests {
    @Test("Stray bullet: one sharp transient at full intensity")
    func strayBullet() {
        let events = HapticPatterns.events(for: .strayBullet)
        #expect(events.count == 1)
        let event = events[0]
        #expect(event.type == .hapticTransient)
        let intensity = event.eventParameters.first { $0.parameterID == .hapticIntensity }?.value
        #expect(intensity == 1.0)
        let sharpness = event.eventParameters.first { $0.parameterID == .hapticSharpness }?.value
        #expect(sharpness == 1.0)
        #expect(HapticPatterns.curves(for: .strayBullet).isEmpty)
    }
    @Test("T-34 firing: main gun then concussive tail")
    func t34Firing() {
        let events = HapticPatterns.events(for: .t34Firing)
        #expect(events.count == 2)
        #expect(events.allSatisfy { $0.type == .hapticTransient })
        #expect(
            events[0].eventParameters.first { $0.parameterID == .hapticIntensity }?.value == 1.0)
        #expect(
            events[1].eventParameters.first { $0.parameterID == .hapticIntensity }?.value == 0.6)
        #expect(events[1].relativeTime > 0, "the tail follows the report")
    }

    @Test("Tank rumble: continuous event swollen by a three-point intensity curve")
    func tankRumble() {
        let events = HapticPatterns.events(for: .tankRumble)
        #expect(events.count == 1)
        let event = events[0]
        #expect(event.type == .hapticContinuous)
        #expect(event.duration == 5)

        let curves = HapticPatterns.curves(for: .tankRumble)
        #expect(curves.count == 1)
        let curve = curves[0]
        #expect(curve.parameterID == .hapticIntensityControl)
        #expect(curve.controlPoints.count == 3)
        #expect(curve.controlPoints.map(\.value) == [0.1, 0.9, 0.1], "swell and fade")
        #expect(curve.controlPoints.last?.relativeTime == 5)
    }
}
