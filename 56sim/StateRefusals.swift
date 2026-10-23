//
//  StateRefusals.swift
//  56sim
//
//  The Ministry of Records does not forbid a repeat stamp; it merely
//  declines it, at length, in writing. One refusal list per forbidden
//  transition: re-neutralizing the already-neutralized, and clearing
//  a neutralized citizen.
//

import Foundation

enum StateRefusals {
    /// 25 refusals for re-neutralizing an already-neutralized citizen.
    static let neutralize: [String] = [
        "He is already neutralized. Neutrality is not a subscription you renew.",
        "The file says neutralized. The file does not negotiate.",
        "You cannot neutralize twice. The second neutralization is the paperwork.",
        "The state notes your enthusiasm and files it under already done.",
        "Re-neutralization requires Form 88, which was neutralized in 1949.",
        "One element, one neutralization. The quota is a matter of dignity.",
        "He is as neutral as yesterday's newspaper. Which you also re-read. No.",
        "The Ministry declines: the deceased is already at full neutral.",
        "Neutralized elements do not accumulate neutralizations. Only dust.",
        "Your stamp has struck this nail already. The nail has stopped moving.",
        "The second neutralization would require a second corpse. Budget declined.",
        "Per regulation 12/7: once is policy. Twice is ambition. Ambition is noted.",
        "The list of neutralized has him exactly once. Keep it that way.",
        "You are trying to paint the lily. The lily is gray. Approved gray.",
        "The state thanks you. The state has already done the state's job.",
        "There is no re-neutralization. There is only remembering harder.",
        "The archive refuses the duplicate. The archive is the stricter brother.",
        "One neutralization is enforcement. Two is vanity.",
        "The file is closed. Closing it again is a sound only clerks make.",
        "Neutralized is a state, comrade, not a hobby.",
        "He cannot be more neutral. The physics have been consulted.",
        "The quota was filled last Tuesday. It remembers.",
        "Declined. The element has already surrendered his share of existence.",
        "Duplicate neutralizations will be reported to your supervisor. Politely.",
        "The Authority is final. The Authority is also, on this matter, complete.",
    ]

    /// 25 refusals for clearing a neutralized citizen.
    static let clear: [String] = [
        "The cleared are citizens. The neutralized are filing. You cannot promote filing.",
        "Cleared requires a living applicant. This one returns mail.",
        "The state cleared him in advance, forever. There is nothing left to clear.",
        "Rehabilitation is for weather. He is history.",
        "The neutralized do not receive documents. They receive distances.",
        "Cleared is a door. He is on the other side of all the doors.",
        "Per regulation: you can clear the suspicious, not the completed.",
        "The Ministry of Records does not un-ring. We do not even re-ring.",
        "His file was cleared of hope last winter. Policy predates you.",
        "You cannot hand a passport to a punchline.",
        "Cleared is for elements. He has graduated to examples.",
        "The request is filed. The request filed itself away.",
        "The state forgives many things. Arithmetic is not among them.",
        "To clear him you would need to un-neutralize. That word does not exist here.",
        "He is not guilty. He is not innocent. He is archived.",
        "The cleared queue is long. The neutralized queue does not exit.",
        "Reinstating him would require a census, a choir, and a miracle. None are budgeted.",
        "Your stamp is bold. The registry is older than your stamp.",
        "Once the ink dries that way, it only dries that way.",
        "Declined with 98% approval from the Department of Declined.",
        "He has been counted among the weather patterns. Weather is not pardoned.",
        "The state can forgive. The state cannot unfinish.",
        "Cleared is behind him. Ahead is only filing cabinets.",
        "The paperwork for his return is itself neutralized, symbolically.",
        "Comrade, the dead vote unanimously against this request.",
    ]

    /// Random refusal for a blocked repeat transition targeting `target`.
    static func refusal(for target: CitizenStatus) -> String {
        let list = target == .neutralized ? neutralize : clear
        return list[Int.random(in: 0..<list.count)]
    }
}
