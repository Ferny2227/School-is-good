"""Builds ShooterGame_v6.rbxlx: puts the scripts from src/ into the place file.

usage: python3 tools/build_rbxlx.py <base.rbxlx> <out.rbxlx>
The base place file only needs the scripts (by name) with a Source property; everything else in it
is kept exactly as it is.
"""
import re, sys, os
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', 'src')
SCRIPTS = ['SConfig', 'SGuns', 'SMaps', 'ShooterMain', 'README', 'ShooterClient']

def cdata(text):
    # "]]>" can't be inside CDATA: split it
    return '<![CDATA[' + text.replace(']]>', ']]]]><![CDATA[>') + ']]>'

def main(base, out):
    xml = open(base, encoding='utf-8').read()
    for name in SCRIPTS:
        src = open(os.path.join(SRC, name + '.lua'), encoding='utf-8').read()
        m = re.search(r'<string name="Name">' + re.escape(name) + r'</string>', xml)
        if not m:
            raise SystemExit('no script called ' + name + ' in ' + base)
        start = xml.index('<ProtectedString name="Source">', m.end())
        body = start + len('<ProtectedString name="Source">')
        end = xml.index('</ProtectedString>', body)
        xml = xml[:body] + cdata(src) + xml[end:]
    open(out, 'w', encoding='utf-8').write(xml)
    # check: every script in the new file is exactly the file in src/
    root = ET.parse(out).getroot()
    found = {}
    for it in root.iter('Item'):
        p = it.find('Properties')
        n = p.find("string[@name='Name']")
        s = p.find("ProtectedString[@name='Source']")
        if s is not None:
            found[n.text] = s.text or ''
    for name in SCRIPTS:
        want = open(os.path.join(SRC, name + '.lua'), encoding='utf-8').read()
        assert found.get(name) == want, name + ' does not match'
    print('wrote', out, '-', len(xml), 'bytes, scripts:', ', '.join('%s (%d lines)' % (n, len(found[n].splitlines())) for n in SCRIPTS))

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
