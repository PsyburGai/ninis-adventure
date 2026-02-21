import re

with open('level_1-3.tmx', 'rb') as f:
    raw = f.read()

lines_lf = raw.split(b'\n')
print('Total LF lines:', len(lines_lf))
print('Line 32:', repr(lines_lf[31][:30]))
print()

tag = b'<data encoding="csv">'
close = b'</data>'
pos = 0
block_num = 0
while True:
    start = raw.find(tag, pos)
    if start == -1:
        break
    end = raw.find(close, start)
    block = raw[start+len(tag):end]
    block_num += 1
    vals = [v.strip() for v in re.split(rb'[,\r\n]+', block) if v.strip()]
    print('Block', block_num, ':', len(vals), 'values')
    print('  Last 20 bytes before close tag:', repr(raw[end-20:end]))
    bad = [v for v in vals if not v.isdigit()]
    if bad:
        print('  BAD:', bad[:5])
    pos = end + len(close)
