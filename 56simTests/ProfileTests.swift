//
//  ProfileTests.swift
//  56simTests
//
//  Verification of the comrade: membership in order, suspicions drawn,
//  nothing forgotten by the Ministry.
//

import Foundation
import Testing

@testable import _6sim

@MainActor
struct ProfileTests {
    private func makeStore() -> StateStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("56sim-tests-\(UUID().uuidString)", isDirectory: true)
        return StateStore(url: directory.appendingPathComponent("state.sqlite"))
    }

    /// Date round-trips through REAL seconds lose sub-microsecond precision;
    /// compare everything else exactly.
    private func sameProfile(_ a: ComradeProfile?, _ b: ComradeProfile) -> Bool {
        guard let a else { return false }
        return a.fullName == b.fullName && a.alias == b.alias
            && a.affiliation == b.affiliation && a.classOrigin == b.classOrigin
            && a.district == b.district && a.membershipNumber == b.membershipNumber
            && a.suspiciousTrait == b.suspiciousTrait && a.assignedTraits == b.assignedTraits
            && a.melody == b.melody && a.yearsLabor == b.yearsLabor
            && abs(a.createdAt.timeIntervalSince1970 - b.createdAt.timeIntervalSince1970) < 0.001
    }

    @Test("saveProfile/profile round-trips every field including drawn traits")
    func profileRoundTrip() {
        let store = makeStore()
        #expect(store.profile() == nil)
        let profile = ComradeProfile(
            fullName: "Horvátné Zsuzsi",
            alias: "Ledger",
            affiliation: "State Beekeeping Directorate",
            classOrigin: "Peasant",
            district: "District IX, Cserkepataka utca 12",
            membershipNumber: "Number 1956-bis, issued in someone else's name",
            suspiciousTrait: "Applauds before the applause is cued",
            assignedTraits: [
                "Owns two pairs of shoes",
                "Whistles in four tones",
                "Has a friend in Vienna",
                "Knows Jurica",
            ],
            melody: "March of the Punctual Pigeons",
            yearsLabor: 41
        )
        store.saveProfile(profile)
        #expect(sameProfile(store.profile(), profile))
        #expect(store.profile()?.assignedTraits.count == 4)

        // One republic, one comrade: the card is replaced, never duplicated.
        var revised = profile
        revised.alias = "Ledger II"
        store.saveProfile(revised)
        #expect(sameProfile(store.profile(), revised))
    }

    @Test("The pool offers exactly 37 suspicions and the full pickers verbatim")
    func poolIntegrity() {
        #expect(Profile.suspiciousTraitPool.count == 37)
        #expect(Set(Profile.suspiciousTraitPool).count == 37)
        #expect(Profile.affiliations.count == 6)
        #expect(Profile.classOrigins.count == 5)
        #expect(Profile.melodies.count == 5)
    }

    @Test("drawTraits returns 4 DISTINCT pool members for scripted rand")
    func drawTraitsDistinct() {
        func scripted(_ values: [Double]) -> () -> Double {
            var iterator = values.makeIterator()
            return { iterator.next() ?? 0.5 }
        }
        for values in [
            [0.0, 0.0, 0.0, 0.0],
            [0.9, 0.9, 0.9, 0.9],
            [0.5, 0.1, 0.9, 0.3],
            [1.0, 1.0, 1.0, 1.0],
        ] {
            let drawn = Profile.drawTraits(rand: scripted(values))
            #expect(drawn.count == 4)
            #expect(Set(drawn).count == 4, "distinct suspicions from \(values)")
            #expect(drawn.allSatisfy { Profile.suspiciousTraitPool.contains($0) })
        }
    }

    @Test("Membership number reads: Number NNNN-bis, issued in someone else's name")
    func membershipNumberFormat() {
        #expect(
            Profile.membershipNumber(rand: { 0.0 })
                == "Number 1000-bis, issued in someone else's name")
        #expect(
            Profile.membershipNumber(rand: { 0.9999 })
                == "Number 9999-bis, issued in someone else's name")
        let produced = Profile.membershipNumber()
        #expect(
            produced.wholeMatch(
                of: #/^Number \d{4}-bis, issued in someone else's name$/#) != nil)
    }
}
