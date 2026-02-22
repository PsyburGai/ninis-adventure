from PIL import Image

# Portal sprite: 16x32px (1 tile wide, 2 tiles tall)
# Style: matches bush/tree - single pixel dark outline, layered shading, no anti-aliasing
# Color: light blue transparent portal with inner glow

w, h = 16, 32
img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
px = img.load()

# Blue portal palette matching the pixel art style of bush/tree
# Dark outline -> mid -> bright -> inner glow (transparent center)
OUT  = (30,  60,  90,  255)  # dark blue outline (matches #273313 darkness level)
DRK  = (40,  90,  140, 255)  # dark blue (matches #316f1b darkness level)
MID  = (60,  130, 190, 255)  # mid blue (matches #6ca030)
BRT  = (100, 180, 230, 255)  # bright blue (matches #93c13b brightness)
GLW  = (160, 210, 245, 180)  # soft glow (semi-transparent)
IN1  = (180, 225, 250, 100)  # inner glow
IN2  = (200, 235, 255, 60)   # near transparent center
T    = (0,   0,   0,   0)    # transparent

# Portal grid row by row (16 wide x 32 tall)
# Arch shape - solid border, glowing semi-transparent interior
grid = [
    # x: 0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
    [T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T ],  # 0
    [T,  T,  T,  T,  OUT,OUT,OUT,OUT,OUT,OUT,OUT,OUT,T,  T,  T,  T ],  # 1
    [T,  T,  T,  OUT,DRK,DRK,MID,BRT,BRT,MID,DRK,DRK,OUT,T,  T,  T ],  # 2
    [T,  T,  OUT,DRK,MID,BRT,GLW,GLW,GLW,GLW,BRT,MID,DRK,OUT,T,  T ],  # 3
    [T,  OUT,DRK,MID,BRT,GLW,IN1,IN2,IN2,IN1,GLW,BRT,MID,DRK,OUT,T ],  # 4
    [T,  OUT,DRK,BRT,GLW,IN1,IN2,IN2,IN2,IN2,IN1,GLW,BRT,DRK,OUT,T ],  # 5
    [OUT,DRK,MID,GLW,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN1,GLW,MID,DRK,OUT],  # 6
    [OUT,DRK,MID,GLW,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN1,GLW,MID,DRK,OUT],  # 7
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 8
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 9
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 10
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 11
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 12
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 13
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 14
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 15
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 16
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 17
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 18
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 19
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 20
    [OUT,DRK,BRT,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN2,IN1,BRT,DRK,OUT],  # 21
    [OUT,DRK,MID,GLW,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN1,GLW,MID,DRK,OUT],  # 22
    [OUT,DRK,MID,GLW,IN1,IN2,IN2,IN2,IN2,IN2,IN2,IN1,GLW,MID,DRK,OUT],  # 23
    [T,  OUT,DRK,MID,GLW,IN1,IN2,IN2,IN2,IN2,IN1,GLW,MID,DRK,OUT,T ],  # 24
    [T,  OUT,DRK,MID,BRT,GLW,IN1,IN1,IN1,IN1,GLW,BRT,MID,DRK,OUT,T ],  # 25
    [T,  T,  OUT,DRK,MID,BRT,BRT,GLW,GLW,BRT,BRT,MID,DRK,OUT,T,  T ],  # 26
    [T,  T,  T,  OUT,OUT,DRK,DRK,DRK,DRK,DRK,DRK,OUT,OUT,T,  T,  T ],  # 27
    [T,  T,  T,  T,  T,  OUT,OUT,OUT,OUT,OUT,T,  T,  T,  T,  T,  T ],  # 28
    [T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T ],  # 29
    [T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T ],  # 30
    [T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T,  T ],  # 31
]

for y, row in enumerate(grid):
    for x, color in enumerate(row):
        px[x, y] = color

img.save('portal_out.png')
print('Saved portal_out.png - 16x32px')
