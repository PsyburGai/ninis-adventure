# Nini's Adventure — Claude Code Project Context

## Project Overview
A 2D side-scrolling platformer built in **Godot 4**, inspired by classic platformers.
The player character is **Nini** — a girl in a blue dress with dark hair.

## Asset Pipeline
- Raw source files: `raw/aseprite/` (Aseprite source files)
- Exported sprites: `assets/sprites/` (PNG spritesheets for Godot)
- Nini sprites live in: `assets/sprites/nini/`
- Enemy sprites live in: `assets/sprites/enemies/`

## Canonical Nini Reference
The **single source of truth** for Nini's appearance is:
- `assets/sprites/nini/Nini-1.png` — walk cycle spritesheet
- `assets/sprites/nini/Nini-1.aseprite` — Aseprite source

### Nini Visual Specs (MUST match across all animations)
- Art style: clean pixel art, side-view (facing right by default)
- Hair: dark black/dark brown, short bob style
- Outfit: blue short-sleeve top, blue skirt/shorts, darker blue at bottom
- Skin tone: warm peach/tan
- Proportions: slightly chibi — larger head relative to body
- Outline: single color dark outline
- Shading: basic/medium — simple highlights on hair and fabric folds
- Color palette: must match Nini-1.png exactly (sample colors from that file)

## Spritesheet Format for Godot
- Layout: **horizontal spritesheet** (all frames in a single row)
- Background: **transparent**
- Scaling: **1x** (no upscaling — Godot handles display scaling)
- Format: **PNG**
- Export to: `assets/sprites/nini/` with descriptive filename

## Animation Standards
- Frame duration: **100ms per frame** unless otherwise specified
- All attack animations: **8 frames**
- All idle animations: **6-8 frames**
- Frame order: left to right in spritesheet

## Pixel Art Rules
- NO anti-aliasing
- NO subpixel rendering
- Maintain consistent pixel size — no mixed resolution elements
- Colors must be sampled/matched from Nini-1.png palette
- Outline pixels must be single-color (not gradient)

## Game Engine
- **Godot 4** — export JSON metadata is NOT needed
- Spritesheets imported directly as SpriteFrames in Godot
- When exporting, use PNG only (no GIF, no JSON sidecar files needed)
