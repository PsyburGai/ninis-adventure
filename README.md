# 🎮 Nini's Adventure

A 2D pixel art platformer built with Godot 4.

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **Godot 4** | Game engine & scripting (GDScript) |
| **Aseprite** | Pixel art & animation (raw source files) |
| **PixelLab** | AI-assisted pixel art generation |
| **Tiled** | Level design (.tmx maps) |
| **VSCode** | Code editing (with Godot Tools extension) |
| **ChipTone** | Sound effects generation |
| **GitHub** | Version control |

---

## 📁 Project Structure

```
Nini's Adventure/
├── project.godot           # Godot project config
├── assets/                 # Game-ready exported assets
│   ├── sprites/
│   │   ├── nini/           # Player spritesheets (PNG)
│   │   ├── enemies/        # Enemy spritesheets (PNG)
│   │   └── items/          # Collectibles & objects (PNG)
│   ├── tilesets/           # Exported tileset PNGs
│   ├── audio/
│   │   ├── sfx/            # Sound effects (.wav from ChipTone)
│   │   └── music/          # Background music (.ogg)
│   ├── fonts/              # Bitmap/pixel fonts
│   └── ui/                 # HUD & menu graphics
├── source/                 # Godot scenes & scripts
│   ├── scenes/
│   │   ├── levels/         # Level .tscn files
│   │   ├── player/         # Player scene
│   │   ├── enemies/        # Enemy scenes
│   │   └── ui/             # HUD, menus
│   └── scripts/
│       ├── player/         # Player GDScript
│       ├── enemies/        # Enemy GDScript
│       ├── managers/       # GameManager, AudioManager, etc.
│       └── ui/             # UI GDScript
├── maps/                   # Tiled .tmx level maps
│   └── world1/
├── raw/                    # Source/editable files (not game-ready)
│   ├── aseprite/           # .aseprite source files
│   │   ├── nini/
│   │   ├── enemies/
│   │   └── tilesets/
│   └── chiptone/           # ChipTone preset saves
└── docs/                   # Design docs, notes, references
```

---

## 🚀 Getting Started

### Prerequisites
- [Godot 4](https://godotengine.org/download)
- [VSCode](https://code.visualstudio.com/) + [Godot Tools extension](https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools)
- [Aseprite](https://www.aseprite.org/)
- [Tiled](https://www.mapeditor.org/)
- [ChipTone](https://sfbgames.itch.io/chiptone)

### Setup
1. Clone the repo: `git clone https://github.com/YOUR_USERNAME/ninis-adventure.git`
2. Open Godot → **Import** → select `project.godot`
3. Open VSCode in the project root for script editing

---

## 🎨 Asset Pipeline

**Sprites:** Edit in Aseprite (`raw/aseprite/`) → Export PNG spritesheet → `assets/sprites/`

**Tilesets:** Design in Aseprite → Export PNG → Import in Tiled → Design levels → Export `.tmx` → `maps/`

**SFX:** Create in ChipTone → Export `.wav` → `assets/audio/sfx/`

---

## 📋 Roadmap

- [ ] Player movement & animation
- [ ] World 1 tileset
- [ ] Level 1-1
- [ ] Basic enemy AI
- [ ] Collectibles system
- [ ] Main menu
- [ ] Audio & SFX
