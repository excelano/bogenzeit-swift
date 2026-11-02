// Solar.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

/// NOAA general solar position: the fractional-year series for the equation
/// of time and the declination, and the three results Bogenzeit takes from
/// them: solar noon, the half arc from noon to a given altitude, and solar
/// midnight. Accuracy against the real Sun is about a minute. Every Bogenzeit
/// port implements this same series, step for step, so that the ports agree
/// with one another to the second.
public enum Solar {
    /// Sun's center at sunrise and sunset: the upper limb on a sea-level
    /// horizon, refraction included (Bogenzeit spec §2.1, §5.4).
    public static let horizonAltitude = -0.833
    public static let civilTwilightAltitude = -6.0
    public static let nauticalTwilightAltitude = -12.0
    public static let astronomicalTwilightAltitude = -18.0

    /// Equation of time in minutes and declination in radians, for a UTC date
    /// and a fractional UTC hour.
    public static func terms(on day: CalendarDay, utcHour: Double) -> (equationOfTime: Double, declination: Double) {
        let g = 2 * Double.pi / Double(day.daysInYear) * (Double(day.dayOfYear - 1) + (utcHour - 12) / 24)
        let eot = 229.18 * (0.000075 + 0.001868 * cos(g) - 0.032077 * sin(g)
            - 0.014615 * cos(2 * g) - 0.040849 * sin(2 * g))
        let decl = 0.006918 - 0.399912 * cos(g) + 0.070257 * sin(g) - 0.006758 * cos(2 * g)
            + 0.000907 * sin(2 * g) - 0.002697 * cos(3 * g) + 0.00148 * sin(3 * g)
        return (eot, decl)
    }

    /// Solar noon (☉) of the solar day labelled `day`, at a longitude in
    /// degrees, east positive.
    public static func noon(on day: CalendarDay, longitude: Double) -> Date {
        let approxHour = 12 - longitude / 15
        let eot = terms(on: day, utcHour: approxHour).equationOfTime
        let minutes = 720 - 4 * longitude - eot
        return day.midnightUTC.addingTimeInterval(minutes * 60)
    }

    /// How long the Sun takes from solar noon to reach an altitude, or why it
    /// never does on that date.
    public enum HalfArc: Equatable, Sendable {
        case seconds(Double)
        case alwaysAbove
        case alwaysBelow

        public var seconds: Double? {
            if case .seconds(let s) = self { return s }
            return nil
        }
    }

    /// Seconds from solar noon to the Sun's center reaching `altitude`, the same
    /// on both sides of noon. The declination is evaluated at solar noon's UTC
    /// hour and minute with the seconds dropped; a port keeps that truncation
    /// so its event times agree with the vectors.
    public static func halfArc(on day: CalendarDay, latitude: Double, longitude: Double, altitude: Double) -> HalfArc {
        let sod = noon(on: day, longitude: longitude).secondsOfUTCDay
        let utcHour = (sod / 3600).rounded(.down) + (sod.truncatingRemainder(dividingBy: 3600) / 60).rounded(.down) / 60
        let decl = terms(on: day, utcHour: utcHour).declination
        let phi = latitude * .pi / 180
        let x = (sin(altitude * .pi / 180) - sin(phi) * sin(decl)) / (cos(phi) * cos(decl))
        if x < -1 { return .alwaysAbove }
        if x > 1 { return .alwaysBelow }
        return .seconds(acos(x) * 180 / .pi * 240)
    }

    /// Solar midnight (○) after the solar day labelled `day`: the midpoint
    /// between that day's noon and the next day's.
    public static func midnight(after day: CalendarDay, longitude: Double) -> Date {
        let n1 = noon(on: day, longitude: longitude)
        let n2 = noon(on: day.adding(days: 1), longitude: longitude)
        return n1.addingTimeInterval(n2.timeIntervalSince(n1) / 2)
    }
}
