import re

for fname in ['level_1-1.tmx', 'level_1-2.tmx', 'level_1-3.tmx']:
    with open(fname, 'rb') as f:
        raw = f.read()

    # Work purely in bytes - no encoding issues
    # Find every data block and rebuild it with NO whitespace before </data>
    result = bytearray()
    pos = 0
    tag_open = b'<data encoding="csv">'
    tag_close = b'</data>'

    while pos < len(raw):
        open_pos = raw.find(tag_open, pos)
        if open_pos == -1:
            result.extend(raw[pos:])
            break

        # Copy everything up to and including <data encoding="csv">
        result.extend(raw[pos:open_pos + len(tag_open)])

        # Find the matching </data>
        close_pos = raw.find(tag_close, open_pos + len(tag_open))

        # Extract the inner CSV content
        inner = raw[open_pos + len(tag_open):close_pos]

        # Parse: split on any combo of comma/CR/LF/space, keep only digits
        tokens = re.split(rb'[,\s]+', inner)
        tokens = [t for t in tokens if t and t.isdigit()]

        # Rebuild: one row of 160 per line, NO trailing comma, NO trailing whitespace
        rows = []
        for i in range(0, len(tokens), 160):
            row = tokens[i:i+160]
            rows.append(b','.join(row))

        # Write rows then </data> with NO leading whitespace
        result.extend(b'\r\n')
        result.extend(b'\r\n'.join(rows))
        result.extend(b'\r\n')
        result.extend(tag_close)

        pos = close_pos + len(tag_close)

    with open(fname, 'wb') as f:
        f.write(bytes(result))

    # Final verification
    final = bytes(result) if fname == 'level_1-3.tmx' else open(fname, 'rb').read()
    blocks = re.findall(rb'<data encoding="csv">(.*?)</data>', final, re.DOTALL)
    for i, b in enumerate(blocks):
        tokens = [t for t in re.split(rb'[,\s]+', b) if t and t.isdigit()]
        trailing = re.findall(rb',[\r\n]', b)
        print(fname, 'block', i+1, ':', len(tokens), 'values, trailing commas:', len(trailing))
        # Show exact bytes before </data>
        close = final.find(b'</data>', final.find(b'<data encoding="csv">'))
        print('  Bytes before </data>:', repr(final[close-10:close+7]))
