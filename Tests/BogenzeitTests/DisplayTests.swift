// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Bogenzeit
import Foundation
import XCTest

final class DisplayTests: XCTestCase {
    func testLowSpansAndMediumKilosecondsMatchTheWrittenForms() throws {
        for v in try vectors() {
            let name = v["name"] as! String
            let r = Reading(at: Date(rfc3339: v["utc"] as! String)!, latitude: v["lat"] as! Double, longitude: v["lon"] as! Double)
            let expected = (v["expected"] as! [String: Any])["written_span"] as? String
            let spans = DisplayedPosition(r, scale: .spans, precision: .low).text
            let polarFallback = DisplayedPosition(r, scale: .kiloseconds, precision: .low).text
            XCTAssertEqual(spans, expected ?? polarFallback, "\(name): spans")
            XCTAssertEqual(DisplayedPosition(r, scale: .kiloseconds, precision: .medium).text, r.offsetForm, "\(name): kiloseconds")
        }
    }

    func testPrecisionSetsTheDecimals() {
        let t = Date(rfc3339: "2026-11-01T17:08:00Z")!
        let r = Reading(at: t, latitude: 29.76, longitude: -95.37)
        let span = { (p: Precision) in DisplayedPosition(r, scale: .spans, precision: p).number }
        let ks = { (p: Precision) in DisplayedPosition(r, scale: .kiloseconds, precision: p).number }
        XCTAssertEqual(span(.low), "18")
        XCTAssertEqual(span(.medium), "17.3")
        XCTAssertEqual(span(.high), "17.28")
        XCTAssertEqual(ks(.low), "3.5")
        XCTAssertEqual(ks(.medium), "3.43")
        XCTAssertEqual(ks(.high), "3.426")
    }

    private func vectors() throws -> [[String: Any]] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("vectors/bz_vectors.json")
        let file = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        return file["vectors"] as! [[String: Any]]
    }
}
