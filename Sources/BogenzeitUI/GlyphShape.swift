// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

#if canImport(SwiftUI)
import Bogenzeit
import SwiftUI

extension Glyph {
    public static let dotRatio = 2.6 / 9

    public func outline(center: CGPoint, radius: CGFloat) -> Path {
        switch self {
        case .noon, .midnight:
            return Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius))
        case .sunrise, .sunset:
            let apex = self == .sunrise ? -radius : radius
            var path = Path()
            path.move(to: CGPoint(x: center.x, y: center.y + apex))
            path.addLine(to: CGPoint(x: center.x - radius, y: center.y - apex))
            path.addLine(to: CGPoint(x: center.x + radius, y: center.y - apex))
            path.closeSubpath()
            return path
        }
    }

    public func dot(center: CGPoint, radius: CGFloat) -> Path? {
        guard self == .noon else { return nil }
        let r = radius * Self.dotRatio
        return Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r))
    }

    public func draw(in context: GraphicsContext, at center: CGPoint, radius: CGFloat, lineWidth: CGFloat, color: Color) {
        context.stroke(outline(center: center, radius: radius), with: .color(color),
                       style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
        if let dot = dot(center: center, radius: radius) {
            context.fill(dot, with: .color(color))
        }
    }
}

public struct GlyphView: View {
    let glyph: Glyph
    let radius: CGFloat
    let lineWidth: CGFloat
    let color: Color

    public init(_ glyph: Glyph, radius: CGFloat, lineWidth: CGFloat, color: Color = .primary) {
        self.glyph = glyph
        self.radius = radius
        self.lineWidth = lineWidth
        self.color = color
    }

    public var body: some View {
        Canvas { context, size in
            glyph.draw(in: context, at: CGPoint(x: size.width / 2, y: size.height / 2), radius: radius,
                       lineWidth: lineWidth, color: color)
        }
        .frame(width: 2 * radius + lineWidth, height: 2 * radius + lineWidth)
        .accessibilityLabel(glyph.name)
    }
}
#endif
