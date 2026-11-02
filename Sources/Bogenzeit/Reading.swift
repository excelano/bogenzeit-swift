// Reading.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

/// The space between a number and its glyph in a display form. The vectors
/// are written with a plain space.
private let separator = " "

public enum SolarAnchor: Sendable, Equatable {
    case noon
    case midnight

    public var glyph: Character {
        switch self {
        case .noon: "☉"
        case .midnight: "○"
        }
    }

    /// The horizon glyph written for the 100-span position before this
    /// anchor (§3.2): △ after sunrise, ▽ after sunset.
    public var horizonGlyph: Character {
        switch self {
        case .noon: "△"
        case .midnight: "▽"
        }
    }

    public var name: String {
        switch self {
        case .noon: "noon"
        case .midnight: "midnight"
        }
    }
}

public enum Quarter: String, Sendable, CaseIterable {
    case afterrise = "Afterrise"
    case forenoon = "Forenoon"
    case afternoon = "Afternoon"
    case foreset = "Foreset"
    case afterset = "Afterset"
    case foremid = "Foremid"
    case aftermid = "Aftermid"
    case forerise = "Forerise"

    public var name: String { rawValue }

    /// The quarter holding a signed span on an arc: start inclusive, end
    /// exclusive, so exactly the anchor is Afternoon or Aftermid (§3.6).
    public static func of(_ anchor: SolarAnchor, span: Double) -> Quarter {
        let index = Int(min(3, max(0, ((span + 100) / 50).rounded(.down))))
        let quarters: [Quarter] = switch anchor {
        case .noon: [.afterrise, .forenoon, .afternoon, .foreset]
        case .midnight: [.afterset, .foremid, .aftermid, .forerise]
        }
        return quarters[index]
    }
}

/// A day without a sunrise or sunset (§3.5).
public enum Polar: Sendable, Equatable {
    /// The Sun never sets: polar day.
    case alwaysAbove
    /// The Sun never rises: polar night.
    case alwaysBelow

    public var name: String {
        switch self {
        case .alwaysAbove: "always_above"
        case .alwaysBelow: "always_below"
        }
    }
}

/// How dark the Nachtbogen is at an instant.
public enum NightPhase: Sendable, Equatable {
    case civilTwilight
    case nauticalTwilight
    case astronomicalTwilight
    case night

    public var name: String {
        switch self {
        case .civilTwilight: "civil twilight"
        case .nauticalTwilight: "nautical twilight"
        case .astronomicalTwilight: "astronomical twilight"
        case .night: "night"
        }
    }
}

/// One Bogenzeit day: the apparent solar day whose ☉ falls on `day`, from
/// its starting ○ (included) to its ending ○ (excluded), per §5.1.
public struct SolarDay: Sendable, Equatable {
    public let day: CalendarDay
    public let noon: Date
    public let midnightStart: Date
    public let midnightEnd: Date
    public let horizon: Solar.HalfArc
    public let civil: Solar.HalfArc
    public let nautical: Solar.HalfArc
    public let astronomical: Solar.HalfArc

    public init(_ day: CalendarDay, latitude: Double, longitude: Double) {
        self.day = day
        noon = Solar.noon(on: day, longitude: longitude)
        midnightStart = Solar.midnight(after: day.adding(days: -1), longitude: longitude)
        midnightEnd = Solar.midnight(after: day, longitude: longitude)
        let arc = { Solar.halfArc(on: day, latitude: latitude, longitude: longitude, altitude: $0) }
        horizon = arc(Solar.horizonAltitude)
        civil = arc(Solar.civilTwilightAltitude)
        nautical = arc(Solar.nauticalTwilightAltitude)
        astronomical = arc(Solar.astronomicalTwilightAltitude)
    }

    public var polar: Polar? {
        switch horizon {
        case .seconds: nil
        case .alwaysAbove: .alwaysAbove
        case .alwaysBelow: .alwaysBelow
        }
    }

    /// Solar noon to sunset, which is also sunrise to solar noon.
    public var halfDay: Double? { horizon.seconds }
    public var tagbogen: Double? { halfDay.map { 2 * $0 } }
    /// Seconds in one day span today.
    public var daySpan: Double? { halfDay.map { $0 / 100 } }
    public var sunrise: Date? { beforeNoon(horizon) }
    public var sunset: Date? { afterNoon(horizon) }

    /// The morning instant at which the Sun reaches the altitude of `arc`.
    public func beforeNoon(_ arc: Solar.HalfArc) -> Date? {
        arc.seconds.map { noon.addingTimeInterval(-$0) }
    }

    /// The evening instant at which the Sun reaches the altitude of `arc`.
    public func afterNoon(_ arc: Solar.HalfArc) -> Date? {
        arc.seconds.map { noon.addingTimeInterval($0) }
    }

    /// Starting ○ to sunrise.
    public var halfNightMorning: Double? { sunrise.map { $0.timeIntervalSince(midnightStart) } }
    /// Sunset to ending ○.
    public var halfNightEvening: Double? { sunset.map { midnightEnd.timeIntervalSince($0) } }

    /// The night phase at an instant of this day, or nil in daylight.
    public func nightPhase(at t: Date) -> NightPhase? {
        let fromNoon = abs(t.timeIntervalSince(noon))
        func within(_ arc: Solar.HalfArc) -> Bool {
            switch arc {
            case .seconds(let s): fromNoon < s
            case .alwaysAbove: true
            case .alwaysBelow: false
            }
        }
        if within(horizon) { return nil }
        if within(civil) { return .civilTwilight }
        if within(nautical) { return .nauticalTwilight }
        if within(astronomical) { return .astronomicalTwilight }
        return .night
    }
}

/// The Bogenzeit date of an instant (§5.1): the label of the solar day that
/// contains it, where a solar day runs from one ○ to the next.
public func bogenzeitDay(of t: Date, longitude: Double) -> CalendarDay {
    let guess = t.addingTimeInterval(longitude / 15 * 3600).utcDay
    for offset in [-1, 0, 1] {
        let d = guess.adding(days: offset)
        let start = Solar.midnight(after: d.adding(days: -1), longitude: longitude)
        let end = Solar.midnight(after: d, longitude: longitude)
        if start <= t && t < end { return d }
    }
    preconditionFailure("every instant falls in one of three neighbouring solar days")
}

/// Where the instant sits on its arc, or why it has no arc position.
public enum Position: Sendable, Equatable {
    /// `span` is signed spans from the anchor, negative before, positive
    /// after; `spanSeconds` is the length of one span of this half-arc.
    case onArc(span: Double, spanSeconds: Double, quarter: Quarter)
    case polar(Polar)
}

public struct Reading: Sendable, Equatable {
    public let instant: Date
    public let latitude: Double
    public let longitude: Double
    public let day: SolarDay
    public let anchor: SolarAnchor
    /// Signed seconds from the anchor: negative before, positive after.
    public let offset: Double
    public let position: Position
    public let nightPhase: NightPhase?

    public init(at t: Date, latitude: Double, longitude: Double) {
        instant = t
        self.latitude = latitude
        self.longitude = longitude
        let day = SolarDay(bogenzeitDay(of: t, longitude: longitude), latitude: latitude, longitude: longitude)
        self.day = day
        nightPhase = day.nightPhase(at: t)
        if let rise = day.sunrise, let set = day.sunset, let halfDay = day.halfDay {
            if rise <= t && t < set {
                let span = arcSpan(t.timeIntervalSince(day.noon), halfDay)
                anchor = .noon
                offset = t.timeIntervalSince(day.noon)
                position = .onArc(span: span, spanSeconds: halfDay / 100, quarter: .of(.noon, span: span))
            } else {
                let (midnight, halfNight) = t >= set
                    ? (day.midnightEnd, day.midnightEnd.timeIntervalSince(set))
                    : (day.midnightStart, rise.timeIntervalSince(day.midnightStart))
                let span = arcSpan(t.timeIntervalSince(midnight), halfNight)
                anchor = .midnight
                offset = t.timeIntervalSince(midnight)
                position = .onArc(span: span, spanSeconds: halfNight / 100, quarter: .of(.midnight, span: span))
            }
        } else {
            let fromNoon = abs(t.timeIntervalSince(day.noon))
            let nearerNoon = fromNoon <= abs(t.timeIntervalSince(day.midnightEnd))
                && fromNoon <= abs(t.timeIntervalSince(day.midnightStart))
            let (anchor, anchorTime): (SolarAnchor, Date) = nearerNoon
                ? (.noon, day.noon)
                : (.midnight, t < day.noon ? day.midnightStart : day.midnightEnd)
            self.anchor = anchor
            offset = t.timeIntervalSince(anchorTime)
            position = .polar(day.polar!)
        }
    }

    public var span: Double? {
        if case .onArc(let span, _, _) = position { return span }
        return nil
    }

    public var spanSeconds: Double? {
        if case .onArc(_, let s, _) = position { return s }
        return nil
    }

    public var quarter: Quarter? {
        if case .onArc(_, _, let q) = position { return q }
        return nil
    }

    public var polar: Polar? { day.polar }

    /// Whole spans, floored toward the past (§5.2).
    public var displaySpan: Int? { span.map { Int($0.rounded(.down)) } }

    /// The offset in tens of seconds, floored toward the past: the ks
    /// readout's two-decimal digit count (§5.2).
    public var displayOffsetSteps: Int { Int((offset / 10).rounded(.down)) }

    public var displayOffsetKs: Double { Double(displayOffsetSteps) / 100 }

    /// `59 ☉`, `☉`, `☉ 3`, and `△` or `▽` for the first span after sunrise
    /// or sunset (§3.2); nil on a polar day.
    public var spanForm: String? {
        guard let span = displaySpan else { return nil }
        let g = String(anchor.glyph)
        if span == -100 { return String(anchor.horizonGlyph) }
        if span < 0 { return "\(-span)\(separator)\(g)" }
        if span == 0 { return g }
        return "\(g)\(separator)\(span)"
    }

    /// `11.77 ks ☉`, `☉`, `☉ 0.70 ks`.
    public var offsetForm: String {
        let g = String(anchor.glyph)
        let steps = displayOffsetSteps
        if steps < 0 { return "\(ks(-steps))\(separator)\(g)" }
        if steps == 0 { return g }
        return "\(g)\(separator)\(ks(steps))"
    }

    /// `59 [11.77 ks] ☉`, `☉`, `☉ 3 [0.70 ks]` (§3.7); nil on a polar day.
    public var combinedForm: String? {
        guard let span = displaySpan else { return nil }
        let g = String(anchor.glyph)
        let steps = displayOffsetSteps
        if span < 0 { return "\(-span)\(separator)[\(ks(-steps))]\(separator)\(g)" }
        if span == 0 && steps == 0 { return g }
        return "\(g)\(separator)\(span)\(separator)[\(ks(steps))]"
    }

    /// The full timestamp (§5.3): date, coordinates and position. A polar day
    /// carries the offset form in place of the combined form.
    public var timestamp: String {
        "\(day.day) | \(latitude), \(longitude) | \(combinedForm ?? offsetForm)"
    }
}

/// Spans from the anchor, held within the arc: the bounds tests put the
/// instant inside the arc, and the clamp stops a last-bit rounding of the
/// subtraction from showing 101 at exact sunrise.
private func arcSpan(_ offset: Double, _ halfArc: Double) -> Double {
    min(100, max(-100, 100 * offset / halfArc))
}

/// Hundredths of a kilosecond as `11.77 ks`.
private func ks(_ steps: Int) -> String {
    String(format: "%d.%02d ks", steps / 100, steps % 100)
}
