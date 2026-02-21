import re

for fname in ['level_1-1.tmx', 'level_1-2.tmx', 'level_1-3.tmx']:
    with open(fname, 'rb') as f:
        raw = f.read()

    text = raw.decode('utf-8')

    # Replace every <data encoding="csv">CONTENT</data> block
    # Ensure: no trailing comma, no trailing whitespace, </data> flush against last value newline
    def clean_block(m):
        inner = m.group(1)
        # Split into lines, strip each, remove empty, remove trailing commas
        lines = [l.strip().rstrip(',') for l in inner.strip().splitlines()]
        lines = [l for l in lines if l]
        # Rejoin with CRLF, close tag on its own line with single space indent
        return '<data encoding="csv">\n' + '\n'.join(lines) + '\n  </data>'

    text = re.sub(
        r'<data encoding="csv">(.*?)</data>',
        clean_block,
        text,
        flags=re.DOTALL
    )

    # Write back with CRLF
    text = text.replace('\r\n', '\n').replace('\n', '\r\n')

    with open(fname, 'wb') as f:
        f.write(text.encode('utf-8'))

    # Verify
    with open(fname, 'rb') as f:
        check = f.read()
    lines = check.split(b'\n')
    print(fname)
    print('  Line 32:', repr(lines[31]))
    # Check no comma+newline
    bad = re.findall(rb',\r?\n', check)
    print('  Trailing commas:', len(bad))
    print()
