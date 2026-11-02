// BoundaryTests.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import Foundation
import XCTest

/// The floor rule (Bogenzeit spec §5.2) and the day switchover (§5.1),
/// checked by stepping across each boundary: the display changes at the
/// boundary and never before it.
final class BoundaryTests: XCTestCase {
    private func houston(_ t: Date) -> Reading {
        Reading(at: t, latitude: 29.76, longitude: -95.37)
    }

    private var houstonDay: SolarDay {
        houston(Date(rfc3339: "2026-11-01T17:08:00Z")!).day
    }

    func testNoonGlyphAppearsOnlyFromExactSolarNoon() {
        let noon = houstonDay.noon
        let before = houston(noon.addingTimeInterval(-0.001))
        XCTAssertEqual(before.spanForm, "1 ☉")
        XCTAssertEqual(before.offsetForm, "0.01 ks ☉")
        XCTAssertEqual(before.combinedForm, "1 [0.01 ks] ☉")
        XCTAssertEqual(before.quarter, .forenoon)
        let at = houston(noon)
        XCTAssertEqual(at.spanForm, "☉")
        XCTAssertEqual(at.offsetForm, "☉")
        XCTAssertEqual(at.combinedForm, "☉")
        XCTAssertEqual(at.quarter, .afternoon)
        let after = houston(noon.addingTimeInterval(150))
        XCTAssertEqual(after.spanForm, "☉")
        XCTAssertEqual(after.combinedForm, "☉ 0 [0.15 ks]")
    }

    func testSunsetShowsOnlyAtExactSunsetAndSwitchesAnchor() {
        let sunset = houstonDay.sunset!
        let before = houston(sunset.addingTimeInterval(-0.001))
        XCTAssertEqual(before.spanForm, "☉ 99")
        XCTAssertEqual(before.quarter, .foreset)
        let at = houston(sunset)
        XCTAssertEqual(at.spanForm, "▽")
        XCTAssertEqual(at.combinedForm, "100 [23.37 ks] ○")
        XCTAssertEqual(at.quarter, .afterset)
        XCTAssertEqual(at.day.day, before.day.day)
    }

    func testSunriseSwitchesAnchorBack() {
        let sunrise = houstonDay.sunrise!
        let before = houston(sunrise.addingTimeInterval(-0.001))
        XCTAssertEqual(before.spanForm, "○ 99")
        XCTAssertEqual(before.quarter, .forerise)
        let at = houston(sunrise)
        XCTAssertEqual(at.spanForm, "△")
        XCTAssertEqual(at.combinedForm, "100 [19.84 ks] ☉")
        XCTAssertEqual(at.quarter, .afterrise)
    }

    func testQuarterBoundaryBelongsToTheQuarterItStarts() {
        let day = houstonDay
        let fifty = day.noon.addingTimeInterval(-day.halfDay! / 2)
        let justAfter = houston(fifty.addingTimeInterval(0.001))
        XCTAssertEqual(justAfter.spanForm, "50 ☉")
        XCTAssertEqual(justAfter.quarter, .forenoon)
        let justBefore = houston(fifty.addingTimeInterval(-0.001))
        XCTAssertEqual(justBefore.spanForm, "51 ☉")
        XCTAssertEqual(justBefore.quarter, .afterrise)
    }

    func testKilosecondReadoutStepsEveryTenSeconds() {
        let noon = houstonDay.noon
        XCTAssertEqual(houston(noon.addingTimeInterval(9.999)).offsetForm, "☉")
        XCTAssertEqual(houston(noon.addingTimeInterval(10)).offsetForm, "☉ 0.01 ks")
        XCTAssertEqual(houston(noon.addingTimeInterval(-10)).offsetForm, "0.01 ks ☉")
        XCTAssertEqual(houston(noon.addingTimeInterval(-10.001)).offsetForm, "0.02 ks ☉")
        XCTAssertEqual(houston(noon.addingTimeInterval(1234.5)).offsetForm, "☉ 1.23 ks")
    }

    func testDateChangesAtSolarMidnight() {
        let day = houstonDay
        let last = houston(day.midnightEnd.addingTimeInterval(-0.001))
        XCTAssertEqual(last.day.day.description, "2026-11-01")
        XCTAssertEqual(last.spanForm, "1 ○")
        let first = houston(day.midnightEnd)
        XCTAssertEqual(first.day.day.description, "2026-11-02")
        XCTAssertEqual(first.spanForm, "○")
        XCTAssertEqual(first.quarter, .aftermid)
        XCTAssertEqual(first.day.midnightStart, day.midnightEnd)
    }

    func testCalendarRoundTripsAndParses() {
        for days in stride(from: -200_000, to: 200_000, by: 37) {
            XCTAssertEqual(CalendarDay(daysSinceEpoch: days).daysSinceEpoch, days)
        }
        XCTAssertEqual(CalendarDay("2028-02-29")?.dayOfYear, 60)
        XCTAssertNil(CalendarDay("2027-02-29"))
        let t = Date(rfc3339: "2026-11-01T17:08:00Z")!
        XCTAssertEqual(t.timeIntervalSince1970, 1_793_552_880)
        XCTAssertEqual(t.rfc3339, "2026-11-01T17:08:00Z")
        XCTAssertEqual(Date(rfc3339: "2026-11-01T11:08:00-06:00"), t)
        XCTAssertNil(Date(rfc3339: "2026-11-01"))
    }
}
