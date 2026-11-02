// CalendarDay.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

/// A Gregorian calendar date, free of any time zone. Bogenzeit labels each
/// solar day with one, and computes with days counted from the Unix epoch.
public struct CalendarDay: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init?(year: Int, month: Int, day: Int) {
        guard (1...12).contains(month), day >= 1, day <= CalendarDay.daysInMonth(year: year, month: month) else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
    }

    /// Parses `YYYY-MM-DD`.
    public init?(_ text: String) {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else {
            return nil
        }
        self.init(year: year, month: month, day: day)
    }

    public static func isLeapYear(_ year: Int) -> Bool {
        year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
    }

    public var daysInYear: Int { CalendarDay.isLeapYear(year) ? 366 : 365 }

    /// 1 for 1 January.
    public var dayOfYear: Int {
        daysSinceEpoch - CalendarDay(year: year, month: 1, day: 1)!.daysSinceEpoch + 1
    }

    /// Days since 1970-01-01, negative before it.
    public var daysSinceEpoch: Int {
        let y = year - (month <= 2 ? 1 : 0)
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doy = (153 * (month > 2 ? month - 3 : month + 9) + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    public init(daysSinceEpoch days: Int) {
        let z = days + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let day = doy - (153 * mp + 2) / 5 + 1
        let month = mp < 10 ? mp + 3 : mp - 9
        self.year = yoe + era * 400 + (month <= 2 ? 1 : 0)
        self.month = month
        self.day = day
    }

    public func adding(days: Int) -> CalendarDay {
        CalendarDay(daysSinceEpoch: daysSinceEpoch + days)
    }

    /// 00:00:00 UTC on this date.
    public var midnightUTC: Date {
        Date(timeIntervalSince1970: Double(daysSinceEpoch) * 86_400)
    }

    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        lhs.daysSinceEpoch < rhs.daysSinceEpoch
    }

    private static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12: 31
        case 4, 6, 9, 11: 30
        case 2: isLeapYear(year) ? 29 : 28
        default: 0
        }
    }
}

extension Date {
    /// The UTC calendar date of this instant.
    public var utcDay: CalendarDay {
        CalendarDay(daysSinceEpoch: Int((timeIntervalSince1970 / 86_400).rounded(.down)))
    }

    /// Seconds since 00:00 UTC of the instant's own date.
    public var secondsOfUTCDay: Double {
        let r = timeIntervalSince1970.truncatingRemainder(dividingBy: 86_400)
        return r < 0 ? r + 86_400 : r
    }

    /// Parses RFC 3339: `2026-11-01T17:08:00Z`, with an optional fraction of a
    /// second and either `Z` or a `±HH:MM` offset.
    public init?(rfc3339 text: String) {
        guard let separator = text.firstIndex(where: { $0 == "T" || $0 == "t" || $0 == " " }),
              let day = CalendarDay(String(text[..<separator])) else { return nil }
        var rest = String(text[text.index(after: separator)...])
        var offset = 0.0
        if rest.hasSuffix("Z") || rest.hasSuffix("z") {
            rest.removeLast()
        } else if let sign = rest.lastIndex(where: { $0 == "+" || $0 == "-" }) {
            let zone = rest[rest.index(after: sign)...].split(separator: ":")
            guard zone.count == 2, let hours = Double(zone[0]), let minutes = Double(zone[1]) else { return nil }
            offset = (rest[sign] == "-" ? -1 : 1) * (hours * 3600 + minutes * 60)
            rest = String(rest[..<sign])
        } else {
            return nil
        }
        let fields = rest.split(separator: ":", omittingEmptySubsequences: false)
        guard fields.count == 3, let hour = Double(fields[0]), let minute = Double(fields[1]),
              let second = Double(fields[2]), hour < 24, minute < 60, second >= 0, second < 61 else { return nil }
        self = day.midnightUTC.addingTimeInterval(hour * 3600 + minute * 60 + second - offset)
    }

    /// RFC 3339 in UTC, truncated toward the past to the whole second.
    public var rfc3339: String {
        let sod = secondsOfUTCDay.rounded(.down)
        let hour = Int(sod / 3600)
        let minute = Int(sod) % 3600 / 60
        let second = Int(sod) % 60
        return String(format: "%@T%02d:%02d:%02dZ", utcDay.description, hour, minute, second)
    }
}
