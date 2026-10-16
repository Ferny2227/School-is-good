# Simulates a player building an airport (buys the cheapest thing it can as soon as it can afford it)
# with the same money formulas as AirportServer, to check that finishing takes about an hour.
#   python3 sim.py
import math
from catalog import ITEMS, STAFF, CATS, CONST
K = dict(passive=1, pax=CONST['paxMult'], checkinFee=CONST['checkinFee'], price=1, staffprice=1)

# the formulas the server uses (keep in sync with AirportServer.server.lua: Econ)
def counters(bought):
    c = {}
    for it in ITEMS:
        if it['key'] in bought:
            for k, v in it['eff'].get('cnt', {}).items(): c[k] = c.get(k, 0) + v
    return c

def cats(bought, staff):
    s = {k: 0.0 for k in CATS}
    s['clean'] = CONST['clean_base']
    for it in ITEMS:
        if it['key'] in bought:
            for k, v in it['eff'].get('cat', {}).items(): s[k] += v
    for st in STAFF:
        n = staff.get(st['key'], 0)
        for k, v in st['cat'].items(): s[k] += v * n
    return {k: min(1.0, v) for k, v in s.items()}

def stars(bought, staff):
    c = cats(bought, staff)
    return 1 + 4 * sum(c.values()) / len(c)

def staff_cap(st, cnt):
    cap = st['capbase'] + (cnt.get(st['need'], 0) * st['capper'] if st['need'] else 0)
    if st.get('capextra'): cap += cnt.get(st['capextra'][0], 0) * st['capextra'][1]
    return cap

def staff_fee(st, n): return int(st['fee'] * 1.35 ** n)

def passenger_rate(bought):
    if 'foundation' not in bought: return 0, 0
    c = counters(bought)
    interval = max(2.5, 16 / (1 + 0.3 * c.get('transport', 0) + 0.15 * c.get('desk', 0) + 0.25 * c.get('gate', 0)))
    cap = min(16, 3 + c.get('desk', 0) + 2 * c.get('gate', 0))
    journey = 60
    return min(1 / interval, cap / journey), cap

def per_passenger(bought, staff, st):
    mult = 0.5 + 0.3 * st
    c = counters(bought)
    money = 0
    stalls = [it for it in ITEMS if it['key'] in bought and it['kind'] == 'stall']
    shops = [it for it in ITEMS if it['key'] in bought and it['kind'] == 'shop']
    if stalls: money += 0.6 * sum(s['eff']['spend'] for s in stalls) / len(stalls) * (1 + 0.1 * staff.get('chef', 0))
    if shops: money += 0.5 * sum(s['eff']['spend'] for s in shops) / len(shops) * (1 + 0.1 * staff.get('clerk', 0))
    if c.get('gate', 0) > 0:
        t = CONST['baseTicket'] + sum(it['eff'].get('ticket', 0) for it in ITEMS if it['key'] in bought)
        tm = 1
        for it in ITEMS:
            if it['key'] in bought: tm *= it['eff'].get('tmult', 1)
        t *= tm * (1 + 0.1 * staff.get('pilot', 0))
        money += t
    if c.get('desk', 0) > 0: money += K['checkinFee']
    return money * mult * K['pax']

def passive(bought):
    return sum(it['eff'].get('inc', 0) for it in ITEMS if it['key'] in bought) * K['passive']

def run(verbose=True):
    cash = CONST['startCash']
    bought, staff = set(), {}
    t = 0
    log = []
    phase_done = {}
    while t < 4 * 3600:
        # buy everything affordable, cheapest first
        while True:
            opts = []
            for it in ITEMS:
                if it['key'] not in bought and all(d in bought for d in it['deps']):
                    opts.append((int(it['price'] * K['price']), 'item', it))
            cnt = counters(bought)
            for stf in STAFF:
                n = staff.get(stf['key'], 0)
                if n < staff_cap(stf, cnt):
                    opts.append((int(staff_fee(stf, n) * K['staffprice']), 'staff', stf))
            if not opts: break
            opts.sort(key=lambda o: o[0])
            price, kind, x = opts[0]
            if price > cash: break
            cash -= price
            if kind == 'item':
                bought.add(x['key'])
                log.append((t, x['name'], price))
            else:
                staff[x['key']] = staff.get(x['key'], 0) + 1
        if len(bought) == len(ITEMS): break
        st = stars(bought, staff)
        rate, cap = passenger_rate(bought)
        inc = passive(bought) + rate * per_passenger(bought, staff, st)
        # inspector: every 6 minutes, 150 * stars^3 once there is a gate
        if t % 360 == 0 and t > 0 and counters(bought).get('gate', 0) > 0:
            cash += int(150 * st ** 3)
        cash += inc
        t += 1
        if verbose and t % 300 == 0:
            print('%3d min: cash %9d  income %7.0f/s  stars %.2f  passengers/min %.1f  items %d/%d  staff %d' % (
                t // 60, cash, inc, st, rate * 60, len(bought), len(ITEMS), sum(staff.values())))
    print('DONE in %.1f minutes (%d items, %d staff)' % (t / 60, len(bought), sum(staff.values())))
    for name in ('Terminal Floor', 'Check-in Desk 1', 'Security Lane 1', 'Gate 1', 'Runway', 'Small Plane (you can fly it!)',
                 'Fighter Jet (you can fly it!)', 'International Status', 'Private Jet (you can fly it!)', 'Golden Terminal'):
        for tt, n, p in log:
            if n == name: print('   %-32s at %5.1f min' % (n, tt / 60))
    return t

if __name__ == '__main__':
    run()
