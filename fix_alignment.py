import os

base = "C:\\Game Project\\Nini's Adventure\\maps\\world1"
levels = ['level_1-1', 'level_1-2', 'level_1-3', 'level_1-4', 'level_1-5']

old = '<property name="res_path" type="file" value="../../source/scenes/objects/portal.tscn"/>'
new = '<property name="res_path" type="file" value="../../source/scenes/objects/portal.tscn"/>\n    <property name="res_alignment" value="topleft"/>'

for l in levels:
    path = os.path.join(base, l + '.tmx')
    content = open(path, encoding='utf-8').read()
    if old in content:
        content = content.replace(old, new)
        open(path, 'w', encoding='utf-8').write(content)
        print('Fixed: ' + l)
    else:
        print('Already fixed or not found: ' + l)
