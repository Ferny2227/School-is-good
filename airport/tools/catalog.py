# Airport Tycoon: everything you can buy and hire. build.py turns this into a Lua table inside the
# server script; sim.py uses it to check that finishing an airport takes about an hour.
#
# Plot coordinates (studs): x = -210..210 across, z = 0 (front, facing the boulevard) .. 620 (back).
# The terminal floor is x -140..140, z 60..320, its top at y = 1.
#
# eff (effects of an item):
#   cat    = rating points per category (each category is capped at 1.0)
#            checkin, security, food, shopping, comfort, clean, gates
#   cnt    = counters (desk, kiosk, lane, gate, bridge, stall, shop, seat, restroom, belt, runway, tower,
#            hangar, fire, transport) used for staff limits, passenger routes and spawn rate
#   inc    = money per second (passive)
#   ticket = added to every boarding pass sold
#   spend  = what a passenger spends at this stall/shop
#   tmult  = ticket multiplier

T = 'terminal'   # pad sits on the terminal floor (y = 1)

ITEMS = []
def item(key, name, price, deps, kind, at=None, pad=(0, 0), where=None, phase=1, **eff):
    ITEMS.append(dict(key=key, name=name, price=price, deps=deps, kind=kind, at=at or {}, pad=pad,
                      floor=1 if where == T else 0, phase=phase, eff=eff))

# ------------------------------------------------------------------ 1. arrival (landside)
item('road', 'Entrance Road', 0, [], 'road', pad=(24, 9))
item('sidewalk', 'Sidewalk', 40, ['road'], 'sidewalk', pad=(0, 30), cat=dict(comfort=0.02))
item('sign', 'Airport Sign', 60, ['road'], 'airportsign', at=dict(x=-170, z=9), pad=(-150, 9))
item('parking', 'Parking Lot', 120, ['road'], 'parking', pad=(-178, 66), inc=10, cnt=dict(transport=1))
item('taxi', 'Taxi Stand', 200, ['sidewalk'], 'taxi', pad=(178, 70), inc=15, cnt=dict(transport=1))
item('foundation', 'Terminal Floor', 350, ['sidewalk'], 'floor', pad=(0, 50))
item('walls', 'Terminal Walls', 800, ['foundation'], 'walls', pad=(0, 70), where=T, cat=dict(comfort=0.04))
item('doors', 'Sliding Doors', 500, ['walls'], 'doors', pad=(30, 50), cat=dict(comfort=0.03), cnt=dict(transport=1))
item('lights', 'Ceiling Lights', 650, ['walls'], 'lights', pad=(-30, 70), where=T, cat=dict(comfort=0.05))
item('infodesk', 'Information Desk', 450, ['foundation'], 'infodesk', at=dict(x=-112, z=74), pad=(-112, 74), where=T,
     cat=dict(comfort=0.03, checkin=0.03))
item('benches', 'Outdoor Benches', 150, ['sidewalk'], 'benches', pad=(-60, 50), cat=dict(comfort=0.02))
item('flags', 'Flag Poles', 300, ['sidewalk'], 'flags', pad=(80, 50), cat=dict(comfort=0.02))
item('trash', 'Trash Bins', 900, ['foundation'], 'trash', pad=(30, 70), where=T, cat=dict(clean=0.08))
item('bus', 'Bus Stop', 1600, ['sidewalk'], 'bus', pad=(178, 122), inc=30, cnt=dict(transport=1))
item('billboards', 'Billboards', 2500, ['road'], 'billboards', pad=(-100, 9), inc=40)

# ------------------------------------------------------------------ 2. check-in
DESK_X = [-112, -80, -48, 48, 80, 112]
for i, x in enumerate(DESK_X):
    item('desk%d' % (i + 1), 'Check-in Desk %d' % (i + 1), [700, 1200, 1900, 2800, 4000, 5500][i],
         ['foundation'] if i == 0 else ['desk%d' % i], 'desk', at=dict(x=x, z=100, n=i + 1), pad=(x, 96), where=T, phase=2,
         cat=dict(checkin=0.12), cnt=dict(desk=1))
item('queue', 'Queue Barriers', 700, ['desk1'], 'queue', pad=(-96, 84), where=T, phase=2, cat=dict(checkin=0.03))
item('carts', 'Luggage Carts', 500, ['desk1'], 'carts', pad=(36, 84), where=T, phase=2, cat=dict(comfort=0.02))
item('belt', 'Baggage Belt', 2200, ['desk2'], 'belt', pad=(-64, 113), where=T, phase=2, cat=dict(checkin=0.06), cnt=dict(belt=1))
item('kioskA', 'Self Check-in Kiosks', 2600, ['desk2'], 'kiosks', at=dict(x=-62), pad=(-62, 72), where=T, phase=2, cat=dict(checkin=0.07))
item('kioskB', 'More Check-in Kiosks', 3600, ['kioskA'], 'kiosks', at=dict(x=62), pad=(62, 72), where=T, phase=2, cat=dict(checkin=0.07))
item('board', 'Departures Board', 1800, ['walls'], 'board', pad=(0, 112), where=T, phase=2, cat=dict(checkin=0.03, gates=0.03))
item('atm', 'ATMs', 3000, ['doors'], 'atm', pad=(-30, 84), where=T, phase=2, inc=40)

# ------------------------------------------------------------------ 3. security
LANE_X = [-30, 30, -60, 60]
item('secwall', 'Security Checkpoint', 2500, ['desk1'], 'secwall', pad=(0, 120), where=T, phase=3, cat=dict(security=0.04))
for i, x in enumerate(LANE_X):
    item('lane%d' % (i + 1), 'Security Lane %d' % (i + 1), [3500, 5500, 8000, 11000][i],
         ['secwall'] if i == 0 else ['lane%d' % i], 'lane', at=dict(x=x), pad=(x, 142), where=T, phase=3,
         cat=dict(security=0.13), cnt=dict(lane=1))
item('office', 'Security Office', 6000, ['lane1'], 'office', pad=(-125, 143), where=T, phase=3, cat=dict(security=0.06))
item('cctv', 'CCTV Cameras', 3000, ['lane1'], 'cctv', pad=(-104, 150), where=T, phase=3, cat=dict(security=0.05))
item('scanner1', 'Body Scanner A', 14000, ['lane2'], 'scanner', at=dict(x=-92), pad=(-92, 142), where=T, phase=3,
     cat=dict(security=0.1), cnt=dict(lane=1))
item('scanner2', 'Body Scanner B', 18000, ['scanner1'], 'scanner', at=dict(x=92), pad=(92, 142), where=T, phase=3,
     cat=dict(security=0.1), cnt=dict(lane=1))
item('k9', 'K9 Unit', 9000, ['lane2'], 'k9', pad=(118, 143), where=T, phase=3, cat=dict(security=0.07))

# ------------------------------------------------------------------ 4. gates, planes and airside
GATE_X = [-105, -35, 35, 105]
for i, x in enumerate(GATE_X):
    item('gate%d' % (i + 1), 'Gate %d' % (i + 1), [5000, 8000, 12000, 17000][i],
         ['lane1'] if i == 0 else ['gate%d' % i], 'gate', at=dict(x=x, n=i + 1), pad=(x, 300), where=T, phase=4,
         cat=dict(gates=0.12), cnt=dict(gate=1), ticket=15)
item('apron', 'Apron', 6000, ['gate1'], 'apron', pad=(-170, 380), phase=4)
for i, x in enumerate(GATE_X):
    item('bridge%d' % (i + 1), 'Jet Bridge %d' % (i + 1), [8000, 11000, 15000, 20000][i],
         ['apron', 'gate%d' % (i + 1)], 'bridge', at=dict(x=x, n=i + 1), pad=(x, 340), phase=4,
         cat=dict(gates=0.08), cnt=dict(bridge=1), ticket=25)
item('vehicles', 'Ground Vehicles', 7000, ['apron'], 'groundvehicles', pad=(0, 430), phase=4, cat=dict(gates=0.03))
item('taxiway', 'Taxiway', 8000, ['apron'], 'taxiway', pad=(0, 460), phase=4, cat=dict(gates=0.03))
item('runway', 'Runway', 15000, ['taxiway'], 'runway', pad=(0, 525), phase=4, cat=dict(gates=0.1), cnt=dict(runway=1), ticket=50)
item('rwlights', 'Runway Lights', 12000, ['runway'], 'rwlights', pad=(-120, 525), phase=4, cat=dict(gates=0.04), ticket=15)
item('windsock', 'Windsock', 1500, ['runway'], 'windsock', pad=(195, 575), phase=4, cat=dict(gates=0.01))
item('tower', 'Control Tower', 50000, ['runway'], 'tower', pad=(-192, 338), phase=4, cat=dict(gates=0.08), cnt=dict(tower=1), ticket=40)
item('radar', 'Radar', 22000, ['tower'], 'radar', pad=(-168, 362), phase=4, cat=dict(gates=0.04))
item('helipad', 'Helipad', 30000, ['apron'], 'helipad', pad=(178, 400), phase=4, inc=50, cat=dict(comfort=0.03))
item('hangar', 'Hangar', 18000, ['runway'], 'hangar', pad=(160, 592), phase=4, cnt=dict(hangar=1))
item('smallplane', 'Small Plane (you can fly it!)', 8000, ['hangar'], 'planepad', at=dict(plane='small', x=128), pad=(128, 572), phase=4)
item('jet', 'Fighter Jet (you can fly it!)', 90000, ['smallplane'], 'planepad', at=dict(plane='jet', x=158), pad=(158, 572), phase=4)
item('privatejet', 'Private Jet (you can fly it!)', 400000, ['jet'], 'planepad', at=dict(plane='private', x=188), pad=(188, 572), phase=4)
item('fuel', 'Fuel Depot', 38000, ['runway'], 'fuel', pad=(-175, 592), phase=4, inc=175)
item('fire', 'Fire Station', 55000, ['runway'], 'firestation', pad=(70, 592), phase=4, cat=dict(gates=0.05, security=0.03), cnt=dict(fire=1), ticket=20)
item('cargo', 'Cargo Terminal', 100000, ['runway'], 'cargo', pad=(-85, 592), phase=4, inc=450)

# ------------------------------------------------------------------ 5. food court
item('foodfloor', 'Food Court', 5000, ['lane1'], 'foodcourt', pad=(-80, 205), where=T, phase=5, cat=dict(food=0.05))
STALLS = [  # name, x, z, facing (degrees: 0 = counter faces +x), colour, spend
    ('Burger Joint', -131, 171, 'Bright red', 12, 6000),
    ('Pizza Place', -131, 189, 'Bright orange', 14, 9000),
    ('Coffee Shop', -131, 207, 'Brown', 10, 12000),
    ('Sushi Bar', -131, 225, 'Institutional white', 22, 17000),
    ('Taco Stand', -100, 243, 'Bright yellow', 16, 23000),
    ('Ice Cream', -66, 243, 'Pink', 12, 30000),
]
for i, (nm, x, z, col, spend, price) in enumerate(STALLS):
    face = 'x' if x < -120 else '-z'
    px, pz = (x + 14, z) if face == 'x' else (x, z - 14)
    item('stall%d' % (i + 1), nm, price, ['foodfloor'] if i == 0 else ['stall%d' % i], 'stall',
         at=dict(x=x, z=z, face=face, color=col, title=nm.upper(), n=i + 1), pad=(px, pz), where=T, phase=5,
         cat=dict(food=0.12), cnt=dict(stall=1), spend=spend)
for i, (x, z) in enumerate([(-95, 182), (-60, 182), (-78, 214)]):
    item('tables%d' % (i + 1), 'Food Court Tables %d' % (i + 1), [2500, 4500, 7000][i], ['foodfloor'], 'tables',
         at=dict(x=x, z=z), pad=(x, z), where=T, phase=5, cat=dict(food=0.04))
item('vending', 'Vending Machines', 3500, ['lane1'], 'vending', pad=(128, 160), where=T, phase=5, cat=dict(food=0.03), inc=20)

# ------------------------------------------------------------------ 6. shops and comfort
SHOPS = [
    ('Souvenir Shop', 131, 171, 'Bright green', 20, 12000),
    ('Bookstore', 131, 189, 'Brown', 15, 15000),
    ('Pharmacy', 131, 207, 'Institutional white', 18, 19000),
    ('Duty Free', 131, 225, 'Royal purple', 40, 26000),
    ('Tech Store', 100, 243, 'Really black', 50, 34000),
    ('Fashion Boutique', 66, 243, 'Hot pink', 45, 44000),
]
for i, (nm, x, z, col, spend, price) in enumerate(SHOPS):
    face = '-x' if x > 120 else '-z'
    px, pz = (x - 14, z) if face == '-x' else (x, z - 14)
    item('shop%d' % (i + 1), nm, price, ['lane1'] if i == 0 else ['shop%d' % i], 'shop',
         at=dict(x=x, z=z, face=face, color=col, title=nm.upper(), n=i + 1), pad=(px, pz), where=T, phase=6,
         cat=dict(shopping=0.14), cnt=dict(shop=1), spend=spend)
for i, (x, z) in enumerate([(50, 186), (88, 186), (50, 216), (88, 216)]):
    item('seats%d' % (i + 1), 'Waiting Seats %d' % (i + 1), [2000, 3500, 5000, 7000][i], ['lane1'] if i == 0 else ['seats%d' % i],
         'seats', at=dict(x=x, z=z), pad=(x, z), where=T, phase=6, cat=dict(comfort=0.05), cnt=dict(seat=1))
item('restrooms', 'Restrooms', 9000, ['lane1'], 'restrooms', pad=(-126, 266), where=T, phase=6, cat=dict(comfort=0.1, clean=0.1), cnt=dict(restroom=1))
item('plants', 'Indoor Plants', 2500, ['walls'], 'plants', pad=(-60, 152), where=T, phase=6, cat=dict(comfort=0.03))
item('charging', 'Charging Stations', 7000, ['seats1'], 'charging', pad=(69, 200), where=T, phase=6, cat=dict(comfort=0.04))
item('arcade', 'Arcade', 38000, ['lane2'], 'arcade', pad=(-39, 266), where=T, phase=6, cat=dict(comfort=0.06), inc=125)
item('kids', 'Kids Play Area', 28000, ['lane2'], 'kids', pad=(120, 266), where=T, phase=6, cat=dict(comfort=0.06))
item('lounge', 'VIP Lounge', 75000, ['gate2'], 'lounge', pad=(-84, 266), where=T, phase=6, cat=dict(comfort=0.1), ticket=40)
item('spa', 'Spa & Massage', 55000, ['gate2'], 'spa', pad=(40, 266), where=T, phase=6, cat=dict(comfort=0.07), inc=150)
item('aquarium', 'Aquarium', 95000, ['lounge'], 'aquarium', pad=(78, 266), where=T, phase=6, cat=dict(comfort=0.08))
item('fountain', 'Terminal Fountain', 40000, ['foodfloor'], 'fountain', pad=(0, 205), where=T, phase=6, cat=dict(comfort=0.05))
item('roof', 'Glass Roof', 85000, ['walls'], 'roof', pad=(-20, 300), where=T, phase=6, cat=dict(comfort=0.1))
item('chandeliers', 'Chandeliers', 45000, ['roof'], 'chandeliers', pad=(20, 300), where=T, phase=6, cat=dict(comfort=0.04))
item('bigscreen', 'Giant Screen', 60000, ['walls'], 'bigscreen', pad=(-40, 50), phase=6, cat=dict(comfort=0.03), inc=100)
item('statue', 'Golden Plane Statue', 140000, ['walls'], 'planestatue', at=dict(x=100, z=9), pad=(100, 9), phase=6, cat=dict(comfort=0.04))

# ------------------------------------------------------------------ 7. landside business
item('rental', 'Car Rental', 18000, ['taxi'], 'rental', pad=(178, 170), phase=7, inc=110, cnt=dict(transport=1))
item('garage', 'Parking Garage', 55000, ['parking'], 'garage', pad=(-178, 250), phase=7, inc=275, cnt=dict(transport=1))
item('hotel', 'Airport Hotel', 180000, ['rental'], 'hotel', pad=(178, 260), phase=7, inc=800)
item('train', 'Train Station', 320000, ['bus'], 'train', pad=(-80, 9), phase=7, inc=1300, cnt=dict(transport=2))

# ------------------------------------------------------------------ 8. mega airport
item('intl', 'International Status', 800000, ['tower', 'gate4'], 'intlsign', pad=(-60, 300), where=T, phase=8,
     cat=dict(gates=0.05), tmult=2)
item('fireworks', 'Fireworks Show', 250000, ['roof'], 'fireworks', pad=(60, 300), where=T, phase=8, cat=dict(comfort=0.03))
item('mascot', 'Airport Mascot', 200000, ['statue'], 'mascot', pad=(180, 9), phase=8, cat=dict(comfort=0.03))
item('golden', 'Golden Terminal', 1500000, ['intl'], 'golden', pad=(-100, 300), where=T, phase=8,
     cat=dict(checkin=0.05, security=0.05, food=0.05, shopping=0.05, comfort=0.05, clean=0.05, gates=0.05), inc=2000)

PHASES = ['Arrival', 'Check-in', 'Security', 'Gates & Planes', 'Food Court', 'Shops & Comfort', 'Business', 'Mega Airport']

# ------------------------------------------------------------------ staff you can hire
# cap: how many you can hire = sum of counters (plus a base). fee grows 35% per hire.
STAFF = [
    dict(key='agent', name='Check-in Agent', fee=400, need='desk', capbase=0, capper=1,
         cat=dict(checkin=0.07), desc='Works a check-in desk. Faster check-in.', shirt='Bright blue'),
    dict(key='officer', name='Security Officer', fee=700, need='lane', capbase=0, capper=2,
         cat=dict(security=0.06), desc='Runs a security lane. Faster, safer security.', shirt='Really black'),
    dict(key='chef', name='Chef', fee=1100, need='stall', capbase=0, capper=1,
         cat=dict(food=0.07), desc='Cooks at a food stall. Better food, more spending.', shirt='Institutional white'),
    dict(key='clerk', name='Shop Clerk', fee=1300, need='shop', capbase=0, capper=1,
         cat=dict(shopping=0.06), desc='Runs a shop. Passengers spend more.', shirt='Bright green'),
    dict(key='janitor', name='Janitor', fee=500, need=None, capbase=2, capper=0, capextra=('restroom', 3),
         cat=dict(clean=0.14), desc='Keeps the airport clean.', shirt='Bright orange'),
    dict(key='gateagent', name='Gate Agent', fee=2200, need='gate', capbase=0, capper=1,
         cat=dict(gates=0.05), desc='Boards passengers at a gate.', shirt='Navy blue'),
    dict(key='pilot', name='Pilot', fee=4500, need='bridge', capbase=0, capper=1,
         cat=dict(gates=0.05), desc='Flies your airliners. More flights, +10% tickets.', shirt='Institutional white', ticketpct=10),
    dict(key='handler', name='Baggage Handler', fee=1800, need='belt', capbase=0, capper=4,
         cat=dict(checkin=0.04), desc='Moves bags. Faster check-in.', shirt='Bright yellow'),
    dict(key='atc', name='Air Traffic Controller', fee=14000, need='tower', capbase=0, capper=2,
         cat=dict(gates=0.06), desc='Works in the control tower. Flights on time.', shirt='Sand blue'),
    dict(key='mechanic', name='Mechanic', fee=8000, need='hangar', capbase=0, capper=2,
         cat=dict(gates=0.03), desc='Tunes your planes: +15% flying speed each.', shirt='Dark stone grey'),
    dict(key='firefighter', name='Firefighter', fee=6000, need='fire', capbase=0, capper=3,
         cat=dict(security=0.03, comfort=0.02), desc='Keeps everyone safe.', shirt='Bright red'),
]

CATS = ['checkin', 'security', 'food', 'shopping', 'comfort', 'clean', 'gates']
CONST = dict(
    startCash=250,
    baseTicket=15,
    walkSpeed=10,
    clean_base=0.15,
    paxMult=6,
    checkinFee=8,
)

if __name__ == '__main__':
    print(len(ITEMS), 'items,', len(STAFF), 'staff roles, total price', sum(i['price'] for i in ITEMS))
    keys = set()
    for it in ITEMS:
        assert it['key'] not in keys, it['key']; keys.add(it['key'])
        for d in it['deps']: assert d in keys, (it['key'], d)
