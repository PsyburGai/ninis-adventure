import re

levels = ['1-1','1-2','1-3','1-4','1-5']
for l in levels:
    path = r'C:\Game Project\Nini' + "'" + r's Adventure\maps\world1\level_' + l + '.tmx'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    idx = content.find('name="solid_ground"')
    chunk = content[idx:idx+6000]
    data_s = chunk.find('>',chunk.find('<data')) + 1
    data_e = chunk.find('</data>')
    rows = chunk[data_s:data_e].strip().split('\n')
    for i, row in enumerate(rows):
        vals = row.strip().rstrip(',').split(',')
        if any(v.strip() not in ('0','') for v in vals):
            print('level_' + l + '  ground_row=' + str(i) + '  y=' + str(i*16) + 'px')
            break
