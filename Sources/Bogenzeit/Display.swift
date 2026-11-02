// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import Foundation

public enum Glyph: Sendable, Equatable {
    case noon
    case midnight
    case sunrise
    case sunset

    public init(_ anchor: SolarAnchor) {
        self = anchor == .noon ? .noon : .midnight
    }

    public static func horizon(before anchor: SolarAnchor) -> Glyph {
        anchor == .noon ? .sunrise : .sunset
    }

    public var character: Character {
        switch self {
        case .noon: "☉"
        case .midnight: "○"
        case .sunrise: "△"
        case .sunset: "▽"
        }
    }

    public var name: String {
        switch self {
        case .noon: "solar noon"
        case .midnight: "solar midnight"
        case .sunrise: "sunrise"
        case .sunset: "sunset"
        }
    }
}

public enum Scale: String, Sendable, CaseIterable, Identifiable {
    case spans
    case kiloseconds

    public static let standard = Scale.spans

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .spans: "Spans"
        case .kiloseconds: "Kiloseconds"
        }
    }
}

public enum Precision: Int, Sendable, CaseIterable, Identifiable {
    case low
    case medium
    case high

    public static let standard = Precision.medium

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    public func decimals(for scale: Scale) -> Int {
        scale == .spans ? rawValue : rawValue + 1
    }
}

public struct DisplayedPosition: Sendable, Equatable {
    public enum Side: Sendable {
        case before
        case after
    }

    public let glyph: Glyph
    public let number: String?
    public let side: Side
    public let unit: String?

    public init(_ reading: Reading, scale: Scale, precision: Precision) {
        if scale == .spans, let span = reading.span {
            let decimals = precision.decimals(for: .spans)
            let factor = Self.power(decimals)
            let steps = Int((span * Double(factor)).rounded(.down))
            unit = nil
            side = steps < 0 ? .before : .after
            if steps == -100 * factor {
                glyph = .horizon(before: reading.anchor)
                number = nil
            } else {
                glyph = Glyph(reading.anchor)
                number = steps == 0 ? nil : Self.decimal(abs(steps), decimals: decimals)
            }
        } else {
            let decimals = precision.decimals(for: .kiloseconds)
            let steps = Int((reading.offset / Double(Self.power(3 - decimals))).rounded(.down))
            glyph = Glyph(reading.anchor)
            unit = "ks"
            side = steps < 0 ? .before : .after
            number = steps == 0 ? nil : Self.decimal(abs(steps), decimals: decimals)
        }
    }

    public var text: String {
        let g = String(glyph.character)
        guard let number else { return g }
        let value = unit.map { "\(number) \($0)" } ?? number
        return side == .before ? "\(value) \(g)" : "\(g) \(value)"
    }

    private static func power(_ n: Int) -> Int {
        (0..<n).reduce(1) { result, _ in result * 10 }
    }

    private static func decimal(_ steps: Int, decimals: Int) -> String {
        guard decimals > 0 else { return "\(steps)" }
        let factor = power(decimals)
        return String(format: "%d.%0\(decimals)d", steps / factor, steps % factor)
    }
}
