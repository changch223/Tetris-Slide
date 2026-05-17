import Foundation

enum Rotation: Int, CaseIterable {
    case deg0 = 0
    case deg90
    case deg180
    case deg270
}

struct PieceShape: Equatable {
    let cells: [GridOffset]
    let width: Int
    let height: Int
}

extension PieceKind {
    func shape(for rotation: Rotation) -> PieceShape {
        Self.shapeTable[self]![rotation]!
    }

    /// Returns all distinct shapes (deduplicated by cell pattern).
    /// O is identical at all rotations; S/Z/I have only 2 distinct rotations.
    func uniqueShapes() -> [(rotation: Rotation, shape: PieceShape)] {
        var seen: [Set<GridOffset>] = []
        var out: [(Rotation, PieceShape)] = []
        for r in Rotation.allCases {
            let s = shape(for: r)
            let key = Set(s.cells)
            if !seen.contains(key) {
                seen.append(key)
                out.append((r, s))
            }
        }
        return out
    }

    private static let shapeTable: [PieceKind: [Rotation: PieceShape]] = [
        .I: [
            .deg0:   PieceShape(cells: o([(0,0),(0,1),(0,2),(0,3)]), width: 4, height: 1),
            .deg90:  PieceShape(cells: o([(0,0),(1,0),(2,0),(3,0)]), width: 1, height: 4),
            .deg180: PieceShape(cells: o([(0,0),(0,1),(0,2),(0,3)]), width: 4, height: 1),
            .deg270: PieceShape(cells: o([(0,0),(1,0),(2,0),(3,0)]), width: 1, height: 4),
        ],
        .O: [
            .deg0:   PieceShape(cells: o([(0,0),(0,1),(1,0),(1,1)]), width: 2, height: 2),
            .deg90:  PieceShape(cells: o([(0,0),(0,1),(1,0),(1,1)]), width: 2, height: 2),
            .deg180: PieceShape(cells: o([(0,0),(0,1),(1,0),(1,1)]), width: 2, height: 2),
            .deg270: PieceShape(cells: o([(0,0),(0,1),(1,0),(1,1)]), width: 2, height: 2),
        ],
        .T: [
            .deg0:   PieceShape(cells: o([(0,0),(0,1),(0,2),(1,1)]), width: 3, height: 2),
            .deg90:  PieceShape(cells: o([(0,1),(1,0),(1,1),(2,1)]), width: 2, height: 3),
            .deg180: PieceShape(cells: o([(0,1),(1,0),(1,1),(1,2)]), width: 3, height: 2),
            .deg270: PieceShape(cells: o([(0,0),(1,0),(1,1),(2,0)]), width: 2, height: 3),
        ],
        .S: [
            .deg0:   PieceShape(cells: o([(0,1),(0,2),(1,0),(1,1)]), width: 3, height: 2),
            .deg90:  PieceShape(cells: o([(0,0),(1,0),(1,1),(2,1)]), width: 2, height: 3),
            .deg180: PieceShape(cells: o([(0,1),(0,2),(1,0),(1,1)]), width: 3, height: 2),
            .deg270: PieceShape(cells: o([(0,0),(1,0),(1,1),(2,1)]), width: 2, height: 3),
        ],
        .Z: [
            .deg0:   PieceShape(cells: o([(0,0),(0,1),(1,1),(1,2)]), width: 3, height: 2),
            .deg90:  PieceShape(cells: o([(0,1),(1,0),(1,1),(2,0)]), width: 2, height: 3),
            .deg180: PieceShape(cells: o([(0,0),(0,1),(1,1),(1,2)]), width: 3, height: 2),
            .deg270: PieceShape(cells: o([(0,1),(1,0),(1,1),(2,0)]), width: 2, height: 3),
        ],
        .J: [
            .deg0:   PieceShape(cells: o([(0,0),(1,0),(1,1),(1,2)]), width: 3, height: 2),
            .deg90:  PieceShape(cells: o([(0,0),(0,1),(1,0),(2,0)]), width: 2, height: 3),
            .deg180: PieceShape(cells: o([(0,0),(0,1),(0,2),(1,2)]), width: 3, height: 2),
            .deg270: PieceShape(cells: o([(0,1),(1,1),(2,0),(2,1)]), width: 2, height: 3),
        ],
        .L: [
            .deg0:   PieceShape(cells: o([(0,2),(1,0),(1,1),(1,2)]), width: 3, height: 2),
            .deg90:  PieceShape(cells: o([(0,0),(1,0),(2,0),(2,1)]), width: 2, height: 3),
            .deg180: PieceShape(cells: o([(0,0),(0,1),(0,2),(1,0)]), width: 3, height: 2),
            .deg270: PieceShape(cells: o([(0,0),(0,1),(1,1),(2,1)]), width: 2, height: 3),
        ],
    ]
}

private func o(_ pairs: [(Int, Int)]) -> [GridOffset] {
    pairs.map { GridOffset(dRow: $0.0, dCol: $0.1) }
}
