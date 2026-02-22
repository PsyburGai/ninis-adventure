import re, os

base = "C:\\Game Project\\Nini's Adventure\\maps\\world1"
levels = ['level_1-1', 'level_1-2', 'level_1-3', 'level_1-4', 'level_1-5']

for level in levels:
    path = os.path.join(base, level + '.tmx')
    content = open(path, encoding='utf-8').read()
    lines = content.split('\n')
    new_lines = []
    for line in lines:
        if ('portal_enter' in line or 'portal_exit' in line) and 'object id' in line:
            line = re.sub(r'( y=")([^"]+)(")', lambda m: m.group(1) + str(round(float(m.group(2)) + 4, 2)) + m.group(3), line)
        new_lines.append(line)
    open(path, 'w', encoding='utf-8').write('\n'.join(new_lines))
    # verify
    for l in new_lines:
        if ('portal_enter' in l or 'portal_exit' in l) and 'object id' in l:
            print(f"{level}: {l.strip()}")
