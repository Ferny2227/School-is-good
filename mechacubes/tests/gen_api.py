# Converts a Roblox API dump (from RobloxAPI/archive) into a Lua table for the fake engine.
#   python3 gen_api.py version-xxxx out.lua
import json, sys
A = '/home/user/robloxapi/archive'
d = json.load(open('%s/data/api-dump/json/%s.json' % (A, sys.argv[1])))

def q(s): return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'
out = ['local API = {classes = {}, enums = {}}']
for c in d['Classes']:
    props, funcs, events, cbs = [], [], [], []
    for m in c.get('Members', []):
        t = m['MemberType']
        tags = m.get('Tags') or []
        if t == 'Property':
            vt = m['ValueType']
            ro = 'true' if ('ReadOnly' in tags) else 'false'
            props.append('[%s]={t=%s,cat=%s,ro=%s}' % (q(m['Name']), q(vt['Name']), q(vt['Category']), ro))
        elif t == 'Function':
            funcs.append('[%s]=true' % q(m['Name']))
        elif t == 'Event':
            events.append('[%s]=true' % q(m['Name']))
        elif t == 'Callback':
            cbs.append('[%s]=true' % q(m['Name']))
    tags = c.get('Tags') or []
    out.append('API.classes[%s]={super=%s,service=%s,notCreatable=%s,props={%s},funcs={%s},events={%s},callbacks={%s}}' % (
        q(c['Name']), q(c['Superclass']), 'true' if 'Service' in tags else 'false', 'true' if 'NotCreatable' in tags else 'false',
        ','.join(props), ','.join(funcs), ','.join(events), ','.join(cbs)))
for e in d.get('Enums', []):
    items = ','.join('[%s]=%d' % (q(i['Name']), i['Value']) for i in e.get('Items', []))
    out.append('API.enums[%s]={%s}' % (q(e['Name']), items))
out.append('return API')
open(sys.argv[2], 'w').write('\n'.join(out))
print(len(d['Classes']), 'classes', len(d.get('Enums', [])), 'enums')
