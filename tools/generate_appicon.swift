#!/usr/bin/env swift
//
// generate_appicon.swift
//
// Generates 3 × 1024x1024 PNG icons for the iOS Universal slots in
// NumberClash/Assets.xcassets/AppIcon.appiconset/:
//
//   Icon.png    — default (light)
//   Icon 1.png  — dark (iOS 18 dark appearance)
//   Icon 2.png  — tinted (iOS 18 tinted appearance, monochrome)
//
// Usage (from repo root):
//
//   swift tools/generate_appicon.swift
//

import AppKit
import CoreGraphics
import Foundation

let SIZE = 1024

// MARK: - Tetris piece layout shared by all variants

struct PiecePlan {
    let cells: [(row: Int, col: Int)]
    let color: CGColor
}

func makePlans(grid: Int, palette: (purple: CGColor, orange: CGColor, cyan: CGColor)) -> [PiecePlan] {
    [
        // T-piece, top center: row 0 cols 1..3, row 1 col 2
        PiecePlan(cells: [(0,1),(0,2),(0,3),(1,2)], color: palette.purple),
        // L-piece, bottom-left: rows 3-4 cols 0..2
        PiecePlan(cells: [(3,0),(4,0),(4,1),(4,2)], color: palette.orange),
        // I-piece vertical, right column: rows 1..4 col 4
        PiecePlan(cells: [(1,4),(2,4),(3,4),(4,4)], color: palette.cyan),
    ]
}

// MARK: - Render

enum Variant { case light, dark, tinted }

func render(variant: Variant) -> Data {
    let space = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(
        data: nil, width: SIZE, height: SIZE,
        bitsPerComponent: 8, bytesPerRow: 0, space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!

    // ── Background ──
    let topColor: CGColor
    let bottomColor: CGColor
    switch variant {
    case .light:
        topColor    = CGColor(red: 0.10, green: 0.14, blue: 0.24, alpha: 1.0)
        bottomColor = CGColor(red: 0.18, green: 0.22, blue: 0.36, alpha: 1.0)
    case .dark:
        topColor    = CGColor(red: 0.04, green: 0.06, blue: 0.10, alpha: 1.0)
        bottomColor = CGColor(red: 0.10, green: 0.13, blue: 0.20, alpha: 1.0)
    case .tinted:
        // Tinted mode requires luminance with alpha — system tints it.
        // Fill with transparent black so the system tint shows through.
        topColor    = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        bottomColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    }

    if variant != .tinted {
        let grad = CGGradient(
            colorsSpace: space,
            colors: [topColor, bottomColor] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(
            grad, start: .zero, end: CGPoint(x: 0, y: SIZE), options: []
        )
    }

    // ── Pieces ──
    // Layout uses a 5x5 grid centered with margin so the icon has breathing room.
    let gridDim = 5
    let usable = Double(SIZE) * 0.78         // 78% of icon for the grid
    let cellSize = usable / Double(gridDim)
    let originX = (Double(SIZE) - usable) / 2
    let originY = (Double(SIZE) - usable) / 2

    let inset  = cellSize * 0.06
    let radius = cellSize * 0.18

    let palette: (CGColor, CGColor, CGColor)
    switch variant {
    case .light:
        palette = (
            CGColor(red: 0.62, green: 0.20, blue: 0.84, alpha: 1.0),  // purple T
            CGColor(red: 1.00, green: 0.58, blue: 0.10, alpha: 1.0),  // orange L
            CGColor(red: 0.10, green: 0.82, blue: 0.92, alpha: 1.0)   // cyan I
        )
    case .dark:
        palette = (
            CGColor(red: 0.78, green: 0.40, blue: 0.95, alpha: 1.0),  // brighter
            CGColor(red: 1.00, green: 0.70, blue: 0.30, alpha: 1.0),
            CGColor(red: 0.30, green: 0.95, blue: 1.00, alpha: 1.0)
        )
    case .tinted:
        // All pieces in same neutral white; iOS will tint them.
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        palette = (white, white, white)
    }

    let plans = makePlans(grid: gridDim, palette: (palette.0, palette.1, palette.2))

    for plan in plans {
        ctx.setFillColor(plan.color)
        for (r, c) in plan.cells {
            let x = originX + Double(c) * cellSize + inset
            // Flip y so (row 0) is visually at top.
            let y = Double(SIZE) - originY - Double(r + 1) * cellSize + inset
            let w = cellSize - inset * 2
            let h = cellSize - inset * 2
            let path = CGPath(
                roundedRect: CGRect(x: x, y: y, width: w, height: h),
                cornerWidth: radius, cornerHeight: radius, transform: nil
            )
            ctx.addPath(path)
            ctx.fillPath()

            // Subtle highlight strip at top of each cell for a 3D feel.
            if variant != .tinted {
                let hl = CGColor(red: 1, green: 1, blue: 1, alpha: 0.18)
                ctx.setFillColor(hl)
                let hlPath = CGPath(
                    roundedRect: CGRect(
                        x: x + cellSize * 0.10,
                        y: y + h - cellSize * 0.18,
                        width: w - cellSize * 0.20,
                        height: cellSize * 0.10
                    ),
                    cornerWidth: cellSize * 0.05,
                    cornerHeight: cellSize * 0.05,
                    transform: nil
                )
                ctx.addPath(hlPath)
                ctx.fillPath()
                ctx.setFillColor(plan.color) // restore
            }
        }
    }

    let img = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: img)
    return rep.representation(using: .png, properties: [:])!
}

// MARK: - Write

let outDir = URL(fileURLWithPath:
    "NumberClash/Assets.xcassets/AppIcon.appiconset",
    relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))

let pairs: [(String, Variant)] = [
    ("Icon.png",   .light),
    ("Icon 1.png", .dark),
    ("Icon 2.png", .tinted),
]

for (name, variant) in pairs {
    let url = outDir.appendingPathComponent(name)
    let data = render(variant: variant)
    try data.write(to: url)
    print("✓ wrote \(url.path) (\(data.count) bytes)")
}

print("\nDone. Open Xcode and rebuild — the app icon should refresh.")
