import re, os

base = "C:\\Game Project\\Nini's Adventure\\maps\\world1"

# Find the LAST row with tiles at x=79 (rightmost column, where portal sits)
# This tells us the exact ground y at the right edge of each level
levels = ['level_1-1', 'level_1-2', 'level_1-3', 'level_1-4', 'level_1-5']

for level in levels:
    path = os.path.join(base, level + '.tmx')
    content = open(path, encoding='utf-8').read()
    
    # Get all layer data sections
    layers = re.findall(r'name="([^"]+)"[^>]*>[\s\S]*?<data[^>]*>([\s\S]*?)</data>', content)
    
    for layer_name, data in layers:
        if 'decoration' in layer_name or 'portal' in layer_name:
            continue
        rows = [r.strip() for r in data.strip().split('\n') if r.strip()]
        # Check rightmost tile (last value in each row)
        for i, row in enumerate(rows):
            vals = [v.strip().rstrip(',') for v in row.rstrip(',').split(',')]
            last_val = vals[-1] if vals else '0'
            if last_val != '0':
                print(f"{level} layer={layer_name}: last solid row at x=79 is row {i}, world_y={i*16}")
