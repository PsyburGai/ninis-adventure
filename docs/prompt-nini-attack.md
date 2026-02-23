# Prompt: Rebuild nini_attack.png to Match Nini-1 Style (8-Frame Attack Animation)

## Task
Rebuild the `nini_attack.png` spritesheet from scratch using the pixel plugin so it matches the visual style, colors, and proportions of `Nini-1.png` exactly, while animating an 8-frame attack sequence.

## Reference Files
- **Style reference (source of truth):** `assets/sprites/nini/Nini-1.png`
- **Current attack file (replace this):** `assets/sprites/nini/nini_attack.png`
- **Attack preview (motion reference):** `assets/sprites/nini/nini_attack_preview.png`

## Step-by-Step Instructions

### Step 1 — Analyze the reference
Open and carefully study `assets/sprites/nini/Nini-1.png`. Note:
- Exact pixel dimensions of each frame (measure the width of one frame in the walk cycle)
- The exact color values used: skin, hair, blue top, blue skirt, dark outline color
- The body proportions: head size vs body, limb thickness
- Shading style: where highlights and shadows fall on the hair and outfit
- Outline style: single dark color, consistent 1px width

### Step 2 — Create the canvas
Create a new Aseprite canvas matching Nini-1's frame dimensions with 8 frames.
- Canvas size: match the per-frame size from Nini-1.png exactly
- 8 frames total
- Transparent background
- Frame duration: 100ms each

### Step 3 — Draw each attack frame
Using ONLY the color palette sampled from Nini-1.png, draw 8 frames that show a complete melee attack cycle. Follow this motion arc:

| Frame | Pose Description |
|-------|-----------------|
| 1 | Wind-up — arm raised back, weight shifted back, anticipation pose |
| 2 | Commit — body leaning forward, arm beginning to swing forward |
| 3 | Strike peak — arm fully extended forward at maximum reach, body weight forward |
| 4 | Follow-through — arm slightly past peak, body still leaning forward |
| 5 | Recovery start — arm pulling back, body beginning to straighten |
| 6 | Recovery mid — returning toward neutral, arm lowering |
| 7 | Recovery end — nearly back to idle stance |
| 8 | Return to idle — standing neutral, matches Nini-1 idle pose |

### Step 4 — Visual consistency rules (CRITICAL)
Every frame MUST:
- Use the exact same colors as Nini-1.png (sample directly, do not approximate)
- Maintain identical head size, body proportions, limb thickness as Nini-1
- Use single-color dark outline (same outline pixel color as Nini-1)
- Have transparent background (no fill, no grey, no white)
- Face right (same direction as Nini-1 walk cycle)
- Match the same shading logic: highlight on top of hair, shadow under skirt fold

### Step 5 — Export
Export as a horizontal spritesheet PNG:
- All 8 frames in a single row, left to right
- Transparent background
- 1x scale (no upscaling)
- Save to: `assets/sprites/nini/nini_attack.png` (overwrite existing)

## Quality Check Before Saving
Before exporting, verify:
- [ ] Colors match Nini-1.png exactly (use color picker to confirm)
- [ ] All 8 frames are present
- [ ] Background is transparent, not filled
- [ ] No anti-aliasing or blurry pixels
- [ ] Proportions match Nini-1 (head is not too small or too large)
- [ ] The attack motion reads clearly as a punch/strike animation
- [ ] Frame 8 returns to a neutral idle-like pose

## Output
Final file: `assets/sprites/nini/nini_attack.png`
- Horizontal spritesheet
- 8 frames × [frame width from Nini-1] wide
- [frame height from Nini-1] tall
- PNG, transparent background
