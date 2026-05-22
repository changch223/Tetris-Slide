# Block Slide — App Icon Brief

Generate a fresh App Store icon that avoids any falling-block-puzzle trademarks
(no falling stacks, no 7-color tetromino palette, no I/O/T/S/Z/J/L
silhouettes). Use **Apple Intelligence Image Playground** or any
1024×1024 PNG generator and drop the result into
`NumberClash/Assets.xcassets/AppIcon.appiconset/`.

## Concept

A minimalist "two-color slide" mark on a soft gradient ground.

- **Canvas**: square, full bleed, no margin text. iOS will round corners.
- **Background**: smooth diagonal gradient from deep indigo
  `#3B3B96` (top-left) to a warm coral `#F97316` (bottom-right).
  Subtle film grain or noise OK; otherwise flat.
- **Foreground (only 2 shapes, only 2 brand colors)**:
  - One **indigo `#5B5BD6`** rounded 3-cell L (corner) — three squares,
    each rounded ~18 % of its side.
  - One **coral `#F97316`** rounded 5-cell U pentomino — five squares
    arranged in a U, same rounding.
  - The two shapes lie on a flat plane (no perspective). The U sits
    just to the right of the L, slightly lower; their edges almost
    touch on one diagonal.
- **Motion cue**: a thin, semi-transparent white arrow / streak
  underneath both shapes pointing right → suggests "slide". Length
  ~40 % of canvas width, soft blur, low opacity.
- **No text**, no letters, no numbers, no stacked-block column,
  no rainbow palette.
- Mood: modern, calm, abstract puzzle — not "block stacker / arcade".

## Required exports

iOS App Icon set requires a 1024×1024 PNG marketing icon plus the
device sizes Xcode generates from it. Easiest:

1. Produce one 1024×1024 PNG (sRGB, no alpha).
2. In Xcode, drag it onto `AppIcon` → "Single Size" / "All Sizes"
   universal slot. Xcode renders the rest.

## Style prompt (paste into Apple Intelligence / Image Playground)

```
A minimalist app icon, 1024×1024, square, no text. Diagonal gradient
background from deep indigo (#3B3B96) top-left to warm coral
(#F97316) bottom-right. In the center, two abstract block clusters
with softly rounded corners: a small three-square indigo (#5B5BD6)
corner shape on the upper-left, and a five-square coral (#F97316)
U-shape on the lower-right, edges nearly touching. Behind them a
thin translucent white horizontal streak suggesting a slide motion.
Flat illustration, no perspective, no shadows except a soft inner
glow, no falling-block stacks, no rainbow palette, only the two brand
colors plus the gradient background. Calm, modern, premium puzzle
game aesthetic.
```

## Don't

- No falling-stack imagery.
- No 7-color piece array (the classic 7-piece tetromino set is a registered trademark).
- No clear borders that look like a grid screen.
- No app-name text on the icon.
