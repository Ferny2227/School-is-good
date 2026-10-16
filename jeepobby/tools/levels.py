# Builds the new Jeep Obby levels (2-5) as plain part lists that patch.py writes into the place.
# Every level runs along +x, high in the sky, one level per row (z). Harder levels get narrower
# roads, faster obstacles and no guard rails.
import math

# BrickColor numbers
WHITE, RED, BLUE, YELLOW, GREEN, ORANGE, BLACK, GREY, DGREY = 1001, 21, 23, 24, 37, 106, 1003, 194, 199
LIME, CYAN, PURPLE, PINK, NEWYELLER, RRED, RBLUE = 1020, 1013, 1031, 1032, 1009, 1004, 1010
# Material enum values
PLASTIC, SMOOTH, NEON, SLATE, CONCRETE, DIAMOND, METAL, ICE, GRASS, SAND, WOOD = 256, 272, 288, 800, 816, 1056, 1088, 1536, 1280, 1296, 512

BASE_Y = 220          # road top height of the new levels
ROW_Z = {2: 520, 3: 760, 4: 1000, 5: 1240}
START_X = -620
THICK = 4
SEAT_H = 2.8          # VehicleSeat centre above the road surface (from the original jeeps)
FACE_X = [0, 0, -1, 0, 1, 0, 1, 0, 0]   # seat rotation that makes a car face +x

THEMES = {
    2: dict(name='Sunny Skyway', road=GREY, edge=BLUE, mat=CONCRETE, accent=YELLOW),
    3: dict(name='Lava Run', road=DGREY, edge=ORANGE, mat=SLATE, accent=RRED),
    4: dict(name='Frozen Peaks', road=WHITE, edge=CYAN, mat=SLATE, accent=RBLUE),
    5: dict(name='Neon Nightmare', road=BLACK, edge=PURPLE, mat=SMOOTH, accent=PINK),
}

def roty(deg):
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    return [c, 0, s, 0, 1, 0, -s, 0, c]
def rotz(deg):
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    return [c, -s, 0, s, c, 0, 0, 0, 1]
def mul(A, B):
    return [sum(A[r * 3 + k] * B[k * 3 + c] for k in range(3)) for r in range(3) for c in range(3)]

UP_X = roty(90)     # wedge rising toward +x
DOWN_X = roty(-90)  # wedge falling toward +x

class Level:
    def __init__(self, n):
        self.n = n
        self.d = n - 1                 # difficulty 1..4
        self.th = THEMES[n]
        self.z = ROW_Z[n]
        self.y = BASE_Y
        self.x = START_X
        self.parts = []                # dicts, see part()
        self.stages = []               # (stage pad index in parts, spawn pos, [slot (pos, rot)])
        self.W = [26, 22, 19, 17][self.d - 1]

    def part(self, name, pos, size, color=None, mat=None, rot=None, cls='Part', collide=True,
             transp=0.0, move=None, velocity=None, refl=0.0, parent=None):
        p = dict(cls=cls, name=name, pos=pos, size=size, color=color if color is not None else self.th['road'],
                 mat=mat if mat is not None else self.th['mat'], rot=rot, collide=collide, transp=transp,
                 move=move, velocity=velocity, refl=refl, parent=parent)
        self.parts.append(p)
        return p

    # ---------------------------------------------------------------- basic pieces
    def slab(self, x0, x1, width=None, color=None, mat=None, z=None, y=None, name='Road'):
        w = width or self.W
        y = self.y if y is None else y
        z = self.z if z is None else z
        return self.part(name, ((x0 + x1) / 2, y - THICK / 2, z), (x1 - x0, THICK, w), color, mat)

    def rails(self, x0, x1, width=None, z=None):
        if self.d > 1: return               # only the first new level has guard rails
        w = width or self.W
        z = self.z if z is None else z
        for side in (-1, 1):
            self.part('Rail', ((x0 + x1) / 2, self.y + 0.75, z + side * (w / 2 + 0.5)), (x1 - x0, 1.5, 1), self.th['edge'], SMOOTH)

    def edges(self, x0, x1, width=None, z=None):
        """thin coloured stripes along the road edges (helps see where the road ends)"""
        w = width or self.W
        z = self.z if z is None else z
        for side in (-1, 1):
            self.part('Edge', ((x0 + x1) / 2, self.y + 0.05, z + side * (w / 2 - 0.5)), (x1 - x0, 0.2, 1), self.th['edge'], NEON, collide=False)

    def kill(self, pos, size, move=None, rot=None):
        return self.part('KillPart', pos, size, RRED, NEON, rot=rot, move=move)

    # ---------------------------------------------------------------- segments
    def road(self, L, rails=True):
        self.slab(self.x, self.x + L); self.edges(self.x, self.x + L)
        if rails: self.rails(self.x, self.x + L)
        self.x += L

    def checkpoint(self, stage, first=False):
        """wide platform: player spawn at the back, car pads spread out across it, then the trigger line"""
        L, Wp = 70, 76
        x0 = self.x
        self.slab(x0, x0 + L, Wp, self.th['edge'] if first else GREY, SMOOTH, name='CheckpointFloor')
        # car pads: 4 lanes, 18 studs apart
        slots = []
        for i, dz in enumerate((-27, -9, 9, 27)):
            pad = self.part('CarPad', (x0 + 34, self.y + 0.1, self.z + dz), (16, 0.2, 10), DGREY, SMOOTH, collide=False)
            slots.append(((x0 + 34, self.y + SEAT_H, self.z + dz), FACE_X))
        spawn = (x0 + 8, self.y + 4, self.z)
        self.part('SpawnMark', (x0 + 8, self.y + 0.1, self.z), (6, 0.2, 6), self.th['accent'], NEON, collide=False)
        # trigger line at the far end (the car must cross it); also a tall invisible box so walkers trigger it
        pad = self.part('Stage%d' % stage, (x0 + L - 4, self.y + 6, self.z), (4, 12, Wp), LIME, NEON, collide=False, transp=0.6)
        self.stages.append(dict(stage=stage, pad=pad, spawn=spawn, slots=slots))
        # side walls so cars don't drive off the pads
        for side in (-1, 1):
            self.part('Rail', (x0 + L / 2, self.y + 1.5, self.z + side * (Wp / 2 + 0.5)), (L, 3, 1), self.th['edge'], SMOOTH)
        self.part('Rail', (x0 + 0.5, self.y + 1.5, self.z), (1, 3, Wp), self.th['edge'], SMOOTH)
        self.x += L
        # funnel down to the road width
        self.road(10)

    def bridge(self, L, w):
        self.slab(self.x, self.x + L, w, self.th['edge'], self.th['mat'], name='Bridge')
        self.x += L

    def slalom(self, n, gap=34):
        """lava tiles that cover alternate sides of the road"""
        L = n * gap + 20
        x0 = self.x
        self.road(L, rails=True)
        cover = 0.58 if self.d < 3 else 0.64
        for i in range(n):
            side = -1 if i % 2 == 0 else 1
            w = self.W * cover
            self.kill((x0 + 18 + i * gap, self.y + 0.3, self.z + side * (self.W / 2 - w / 2)), (8, 0.6, w))

    def sweepers(self, n, gap=36):
        """kill bars that slide across the road"""
        L = n * gap + 24
        x0 = self.x
        self.road(L, rails=False)
        period = max(1.8, 3.6 - 0.45 * self.d)
        amp = self.W / 2 - 2
        for i in range(n):
            self.kill((x0 + 20 + i * gap, self.y + 2.5, self.z), (3, 5, 6 + self.d),
                      move='slide 0 0 %g %g %g' % (amp, period, i * 0.37))

    def spinner(self):
        """round arena with a spinning kill bar (or two on hard levels)"""
        R = self.W / 2 + 14
        x0 = self.x
        self.slab(x0, x0 + 12, None)
        cx = x0 + 12 + R
        self.part('Arena', (cx, self.y - THICK / 2, self.z), (2 * R, THICK, 2 * R), self.th['road'], self.th['mat'])
        self.part('ArenaRim', (cx, self.y + 0.05, self.z), (2 * R - 2, 0.2, 2 * R - 2), self.th['edge'], NEON, collide=False, transp=0.5)
        speed = 50 + 18 * self.d
        self.kill((cx, self.y + 2.2, self.z), (2 * R - 6, 4, 2.5), move='spin %g' % speed)
        if self.d >= 3:
            self.kill((cx, self.y + 2.2, self.z), (2.5, 4, 2 * R - 6), move='spin %g' % speed)
        self.x = cx + R
        self.road(14)

    def pistons(self, n, gap=30):
        """blocks that slam down onto the road"""
        L = n * gap + 20
        x0 = self.x
        self.road(L, rails=True)
        period = max(2.0, 3.4 - 0.35 * self.d)
        for i in range(n):
            # base position is half way up; it moves +-amp in y, so the bottom touches the road
            h = 8
            amp = 9
            self.kill((x0 + 18 + i * gap, self.y + h / 2 + amp + 0.2, self.z), (10, h, self.W - 1),
                      move='slide 0 %g 0 %g %g' % (amp, period, i * 0.5))

    def blink(self, n, L=26):
        """road tiles that vanish for a moment (gaps under them)"""
        period = max(3.0, 5.0 - 0.5 * self.d)
        for i in range(n):
            x0 = self.x
            solid = i % 2 == 0
            self.part('BlinkTile' if not solid else 'Road', (x0 + L / 2, self.y - THICK / 2, self.z), (L, THICK, self.W),
                      self.th['accent'] if not solid else self.th['road'], SMOOTH if not solid else self.th['mat'],
                      move=('blink %g %g %g' % (period, period * 0.62, i * 0.4)) if not solid else None)
            self.x += L
        self.road(10)

    def wind(self, L):
        """sideways conveyor: pushes cars toward the edge"""
        x0 = self.x
        self.road(L, rails=False)
        for i in range(int(L // 40)):
            side = 1 if i % 2 == 0 else -1
            self.part('Wind', (x0 + 20 + i * 40, self.y + 0.05, self.z), (36, 0.2, self.W - 2), CYAN, NEON, collide=True,
                      transp=0.4, velocity=(0, 0, side * (14 + 8 * self.d)))

    def jump(self, gap, drop):
        """boost pad, ramp, gap, lower landing"""
        self.road(16)
        self.part('Boost', (self.x - 8, self.y + 0.05, self.z), (14, 0.2, self.W - 4), self.th['accent'], NEON, velocity=(70 + 10 * self.d, 0, 0))
        rl, rh = 24, 4
        # WedgePart: tall end at its back (+z) face, so turning +z toward +x makes it rise toward +x
        self.part('Ramp', (self.x + rl / 2, self.y + rh / 2, self.z), (self.W, rh, rl), self.th['edge'], self.th['mat'], rot=UP_X, cls='WedgePart')
        self.x += rl + gap
        self.y -= drop
        self.slab(self.x, self.x + 40); self.edges(self.x, self.x + 40)
        self.x += 40

    def hill(self, rise):
        L = 30
        self.part('Ramp', (self.x + L / 2, self.y + rise / 2, self.z), (self.W, rise, L), self.th['road'], self.th['mat'], rot=UP_X, cls='WedgePart')
        self.x += L
        self.y += rise
        self.road(26)
        self.part('Ramp', (self.x + L / 2, self.y - rise / 2, self.z), (self.W, rise, L), self.th['road'], self.th['mat'], rot=DOWN_X, cls='WedgePart')
        self.x += L
        self.y -= rise

    def zigzag(self, n, shift):
        """road jinks sideways: left, right, left..."""
        seg = 40
        for i in range(n):
            dz = shift if i % 2 == 0 else -shift
            ang = math.degrees(math.atan2(dz, seg))
            length = math.hypot(seg, dz)
            cz = self.z + dz / 2
            # turn pad at the corner
            self.part('Road', (self.x, self.y - THICK / 2, self.z), (self.W, THICK, self.W), self.th['road'], self.th['mat'])
            self.part('Road', (self.x + seg / 2, self.y - THICK / 2 - 0.01, cz), (length, THICK, self.W * 0.8),
                      self.th['road'], self.th['mat'], rot=roty(-ang))
            self.x += seg
            self.z += dz
        self.part('Road', (self.x, self.y - THICK / 2, self.z), (self.W, THICK, self.W), self.th['road'], self.th['mat'])
        # bring the road back to the level's row
        back = ROW_Z[self.n] - self.z
        if abs(back) > 0.5:
            ang = math.degrees(math.atan2(back, seg))
            self.part('Road', (self.x + seg / 2, self.y - THICK / 2 - 0.01, self.z + back / 2), (math.hypot(seg, back), THICK, self.W * 0.8),
                      self.th['road'], self.th['mat'], rot=roty(-ang))
            self.x += seg
            self.z = ROW_Z[self.n]
        self.road(10)

    def ice(self, L):
        self.slab(self.x, self.x + L, None, CYAN, ICE, name='Ice')
        self.edges(self.x, self.x + L)
        self.x += L

    def finish(self, last):
        L = 40
        self.slab(self.x, self.x + L, 50, YELLOW if last else self.th['edge'], SMOOTH, name='FinishFloor')
        name = 'WinPad' if last else 'LevelEnd'
        self.part(name, (self.x + L / 2, self.y + 6, self.z), (10, 12, 46), NEWYELLER if last else LIME, NEON, collide=False, transp=0.35)
        # arch
        for side in (-1, 1):
            self.part('Arch', (self.x + L / 2, self.y + 9, self.z + side * 24), (4, 18, 4), self.th['accent'], NEON)
        self.part('Arch', (self.x + L / 2, self.y + 19, self.z), (4, 3, 52), self.th['accent'], NEON)
        self.x += L

    def killfloor(self):
        x0, x1 = START_X - 60, self.x + 60
        self.parts.insert(0, dict(cls='Part', name='KillFloor', pos=((x0 + x1) / 2, BASE_Y - 70, ROW_Z[self.n]), size=(x1 - x0, 2, 400),
                                  color=RRED, mat=SMOOTH, rot=None, collide=False, transp=1, move=None, velocity=None, refl=0, parent=None))


def build():
    levels = []
    stage = 3
    for n in (2, 3, 4, 5):
        L = Level(n)
        d = L.d
        L.checkpoint(stage, first=True); stage += 1
        if n == 2:
            L.road(40); L.slalom(4); L.hill(8); L.sweepers(3); L.bridge(50, 16); L.road(20)
            L.checkpoint(stage); stage += 1
            L.zigzag(4, 14); L.spinner(); L.pistons(3); L.jump(8, 6); L.road(20)
        elif n == 3:
            L.road(30); L.sweepers(4); L.blink(5); L.slalom(5); L.wind(80)
            L.checkpoint(stage); stage += 1
            L.spinner(); L.bridge(60, 14); L.pistons(4); L.jump(10, 8); L.zigzag(4, 16); L.road(20)
        elif n == 4:
            L.road(30); L.ice(60); L.sweepers(4); L.zigzag(5, 16); L.pistons(4); L.bridge(70, 13)
            L.checkpoint(stage); stage += 1
            L.spinner(); L.blink(7); L.wind(80); L.ice(50); L.slalom(5); L.jump(11, 8); L.road(20)
        else:
            L.road(30); L.sweepers(5); L.bridge(80, 12); L.spinner(); L.pistons(5); L.blink(7)
            L.checkpoint(stage); stage += 1
            L.zigzag(6, 18); L.wind(120); L.spinner(); L.jump(12, 9); L.slalom(6); L.sweepers(5); L.bridge(60, 11); L.road(20)
        L.finish(last=(n == 5))
        L.killfloor()
        levels.append(L)
    return levels

if __name__ == '__main__':
    for L in build():
        print(L.n, L.th['name'], 'parts', len(L.parts), 'x end', round(L.x), 'stages', [s['stage'] for s in L.stages])
