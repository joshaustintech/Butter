import CoreGraphics
import SwiftUI

/// Geometry of the laurel behind the detail hero's monogram: eight leaves
/// per side arcing up around the disc, mirrored left and right.
enum Laurel {
    struct Leaf: Equatable {
        /// Offset from the disc's centre, y pointing down.
        let center: CGPoint
        let rotation: Angle
    }

    static let leavesPerSide = 8
    private static let firstAngle = 115.0
    private static let step = 19.0

    /// Leaves in left/right pairs, starting at the bottom of the arc.
    static func leaves(radius: CGFloat) -> [Leaf] {
        (0..<leavesPerSide).flatMap { index -> [Leaf] in
            let degrees = firstAngle + step * Double(index)
            let radians = degrees * .pi / 180
            let x = radius * cos(radians), y = radius * sin(radians)
            return [
                Leaf(center: CGPoint(x: x, y: y), rotation: .degrees(degrees + 90)),
                Leaf(center: CGPoint(x: -x, y: y), rotation: .degrees(-(degrees + 90))),
            ]
        }
    }
}
