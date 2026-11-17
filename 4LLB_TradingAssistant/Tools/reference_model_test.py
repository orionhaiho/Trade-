#!/usr/bin/env python3
"""
Line-by-line Python transliteration of the PURE 4LLB MQL5 functions
(LLB_Utils / LLB_Levels / LLB_Strategy / LLB_StopLoss) and the same test
vectors as MQL5/Scripts/4LLB/4LLB_UnitTests.mq5.

Purpose: verify the algorithms and the expected values of the MQL5 unit
tests in an environment without MetaTrader. It does NOT replace running
4LLB_UnitTests.mq5 in MT5 (that is the real evidence for the MQL5 code).
"""
import math
import sys

# ---- SRS constants (LLB_Defines.mqh)
PIVOT_LEFT = PIVOT_RIGHT = 3
SWEEP_MIN_ATR, SWEEP_MAX_ATR = 0.05, 0.50
BREAKOUT_ATR, RETEST_ATR, RETEST_MAX_BARS = 0.10, 0.15, 4
SL_BUFFER_TICKS, SL_BUFFER_ATR, RR = 2, 0.05, 2.0
BUY, SELL = 0, 1
P1, P2, P3, P4 = 1, 2, 3, 4
NEAREST_PRICE, NEAREST_TIME = 0, 1
SETUP_EXTREME, CONFIRMED_PIVOT = 0, 1


class Bar:
    def __init__(self, o, h, l, c, t=0):
        self.open, self.high, self.low, self.close, self.time = o, h, l, c, t


# ---- LLB_Utils
def round_to_tick(price, tick, mode):
    q = price / tick
    if mode < 0:
        r = math.floor(q + 1e-7)
    elif mode > 0:
        r = math.ceil(q - 1e-7)
    else:
        r = math.floor(q + 0.5) if q >= 0 else -math.floor(-q + 0.5)   # MathRound
    return r * tick


def norm_price(price, tick, digits, mode):
    return round(round_to_tick(price, tick, mode), digits)


def above(a, b, tick):
    return (a - b) > tick * 0.5


def below(a, b, tick):
    return (b - a) > tick * 0.5


def step_digits(step):
    d, s = 0, step
    while d < 8 and abs(s - round(s)) > 1e-9:
        s *= 10.0
        d += 1
    return d


def volume_down(v, step):
    if step <= 0 or v <= 0:
        return 0.0
    return round(math.floor(v / step + 1e-9) * step, step_digits(step))


def calc_risk_lots(risk_money, loss_per_lot, vmin, vmax, step):
    if risk_money <= 0:
        return 0.0, "RISK_MONEY_INVALID"
    if loss_per_lot <= 0:
        return 0.0, "LOSS_PER_LOT_INVALID"
    raw = risk_money / loss_per_lot
    lots = volume_down(raw, step)
    if lots > vmax:
        lots = volume_down(vmax, step)
    if lots < vmin - step * 1e-6:
        return 0.0, "RISK_LOTS_BELOW_MIN"
    return lots, ""


def find_touch(ticks, direction, level, from_msc, tick):
    tol = tick * 0.5
    last_bid = last_ask = 0.0
    for (msc, bid, ask) in ticks:
        if bid > 0:
            last_bid = bid
        if ask > 0:
            last_ask = ask
        if msc < from_msc:
            continue
        if direction == BUY and last_bid > 0 and last_bid <= level + tol:
            return True, msc, last_bid
        if direction == SELL and last_ask > 0 and last_ask >= level - tol:
            return True, msc, last_ask
    return False, 0, 0.0


def sl_within_approved(d, cur, approved, tick):
    if cur <= 0 or approved <= 0:
        return False
    return cur >= approved - tick * 0.5 if d == BUY else cur <= approved + tick * 0.5


# ---- LLB_Levels
def is_pivot_high(r, n, i):
    if i - PIVOT_RIGHT < 0 or i + PIVOT_LEFT >= n:
        return False
    h = r[i].high
    return all(h > r[i + k].high for k in range(1, PIVOT_LEFT + 1)) and all(h > r[i - k].high for k in range(1, PIVOT_RIGHT + 1))


def is_pivot_low(r, n, i):
    if i - PIVOT_RIGHT < 0 or i + PIVOT_LEFT >= n:
        return False
    l = r[i].low
    return all(l < r[i + k].low for k in range(1, PIVOT_LEFT + 1)) and all(l < r[i - k].low for k in range(1, PIVOT_RIGHT + 1))


def find_swing_beyond(r, n, as_of, high, threshold, inclusive, lookback, nearest):
    if as_of < 1 or lookback < 1 or threshold <= 0:
        return None
    start = as_of + PIVOT_RIGHT
    last = min(start + lookback - 1, n - 1 - PIVOT_LEFT)
    best = None
    for i in range(start, last + 1):
        piv = is_pivot_high(r, n, i) if high else is_pivot_low(r, n, i)
        if not piv:
            continue
        p = r[i].high if high else r[i].low
        if high:
            beyond = p >= threshold if inclusive else p > threshold
        else:
            beyond = p <= threshold if inclusive else p < threshold
        if not beyond:
            continue
        if best is None:
            best = (p, i)
            if nearest == NEAREST_TIME:
                return best
            continue
        if (high and p < best[0]) or (not high and p > best[0]):
            best = (p, i)
    return best


class Levels:
    def __init__(self, pdh=0, pdl=0, p3=0, p4=0, valid=False, why=""):
        self.pdh, self.pdl, self.p3, self.p4, self.valid, self.why = pdh, pdl, p3, p4, valid, why


def compute_levels(r, n, as_of, pdh, pdl, lookback, nearest):
    lv = Levels(pdh, pdl)
    if pdh <= 0 or pdl <= 0 or not (pdl < pdh):
        lv.why = "PDH_PDL_INVALID"
        return lv
    s3 = find_swing_beyond(r, n, as_of, False, pdl, False, lookback, nearest)
    s4 = find_swing_beyond(r, n, as_of, True, pdh, False, lookback, nearest)
    if s3:
        lv.p3 = s3[0]
    if s4:
        lv.p4 = s4[0]
    if not s3:
        lv.why = "P3_MISSING"
        return lv
    if not s4:
        lv.why = "P4_MISSING"
        return lv
    if not (lv.p3 < lv.pdl < lv.pdh < lv.p4):
        lv.why = "ORDER"
        return lv
    lv.valid, lv.why = True, "OK"
    return lv


# ---- LLB_Strategy
def sweep_at_level(bar, direction, level, atr, tick):
    if level <= 0 or atr <= 0:
        return False, 0.0
    if direction == SELL:
        if not above(bar.high, level, tick) or not below(bar.close, level, tick) or not (bar.close < bar.open):
            return False, 0.0
        depth = bar.high - level
    else:
        if not below(bar.low, level, tick) or not above(bar.close, level, tick) or not (bar.close > bar.open):
            return False, 0.0
        depth = level - bar.low
    return (SWEEP_MIN_ATR * atr - 1e-10 <= depth <= SWEEP_MAX_ATR * atr + 1e-10), depth


def reference_swing(r, n, t, direction, extreme, mode, nearest, lookback):
    if mode == SETUP_EXTREME:
        return extreme
    sp = find_swing_beyond(r, n, t, direction == SELL, extreme, True, lookback, nearest)
    return sp[0] if sp else None


def detect_sweep(r, n, t, lv, atr, tick, digits, mode=SETUP_EXTREME, nearest=NEAREST_PRICE, lookback=100):
    if not lv.valid:
        return None
    s4, _ = sweep_at_level(r[t], SELL, lv.p4, atr, tick)
    s1, _ = sweep_at_level(r[t], SELL, lv.pdh, atr, tick)
    b3, _ = sweep_at_level(r[t], BUY, lv.p3, atr, tick)
    b2, _ = sweep_at_level(r[t], BUY, lv.pdl, atr, tick)
    if s4 or s1:
        d, level, also = SELL, (P4 if s4 else P1), (s4 and s1)
    elif b3 or b2:
        d, level, also = BUY, (P3 if b3 else P2), (b3 and b2)
    else:
        return None
    entry = norm_price(r[t].high + tick, tick, digits, 0) if d == BUY else norm_price(r[t].low - tick, tick, digits, 0)
    extreme = r[t].low if d == BUY else r[t].high
    ref = reference_swing(r, n, t, d, extreme, mode, nearest, lookback)
    if ref is None:
        return None
    return dict(dir=d, level=level, entry=entry, ref=ref, also=also)


def breakout_close(bar, d, level, atr):
    return bar.close > level + BREAKOUT_ATR * atr if d == BUY else bar.close < level - BREAKOUT_ATR * atr


def retest_confirm(bar, d, level, atr):
    if d == BUY:
        return abs(bar.low - level) <= RETEST_ATR * atr + 1e-10 and bar.close > bar.open
    return abs(bar.high - level) <= RETEST_ATR * atr + 1e-10 and bar.close < bar.open


def detect_breakout_dir(r, n, t, lv_at, atr_at, tick, digits, d, mode=SETUP_EXTREME, nearest=NEAREST_PRICE, lookback=100):
    for b in range(t + 1, t + RETEST_MAX_BARS + 1):
        if b + 1 >= n or b >= len(lv_at) or b + 1 >= len(atr_at):
            break
        if not lv_at[b].valid or atr_at[b] <= 0 or atr_at[b + 1] <= 0:
            continue
        level = lv_at[b].p4 if d == BUY else lv_at[b].p3
        if not breakout_close(r[b], d, level, atr_at[b]):
            continue
        if breakout_close(r[b + 1], d, level, atr_at[b + 1]):
            continue
        if any(atr_at[j] > 0 and retest_confirm(r[j], d, level, atr_at[j]) for j in range(b - 1, t, -1)):
            continue
        if not retest_confirm(r[t], d, level, atr_at[t]):
            continue
        entry = norm_price(r[t].high + tick, tick, digits, 0) if d == BUY else norm_price(r[t].low - tick, tick, digits, 0)
        if d == BUY:
            extreme = min(r[k].low for k in range(t, b))
        else:
            extreme = max(r[k].high for k in range(t, b))
        ref = reference_swing(r, n, t, d, extreme, mode, nearest, lookback)
        if ref is None:
            return None
        return dict(dir=d, level=(P4 if d == BUY else P3), entry=entry, ref=ref, b=b)
    return None


def detect_breakout(r, n, t, lv_at, atr_at, tick, digits):
    return detect_breakout_dir(r, n, t, lv_at, atr_at, tick, digits, BUY) or detect_breakout_dir(r, n, t, lv_at, atr_at, tick, digits, SELL)


# ---- LLB_StopLoss
def compute_stops(d, entry, ref, atr, tick, digits):
    if tick <= 0 or entry <= 0 or ref <= 0 or atr <= 0:
        return None
    buf = max(SL_BUFFER_TICKS * tick, SL_BUFFER_ATR * atr)
    if d == BUY:
        sl = norm_price(ref - buf, tick, digits, -1)
        risk = entry - sl
        tp = norm_price(entry + RR * risk, tick, digits, 0)
        if not (below(sl, ref, tick) and below(ref, entry, tick) and below(entry, tp, tick)):
            return None
    else:
        sl = norm_price(ref + buf, tick, digits, 1)
        risk = sl - entry
        tp = norm_price(entry - RR * risk, tick, digits, 0)
        if not (below(tp, entry, tick) and below(entry, ref, tick) and below(ref, sl, tick)) or tp <= 0:
            return None
    if risk < tick * 0.5:
        return None
    return dict(sl=sl, tp=tp, buf=buf, rr=abs(tp - entry) / abs(entry - sl))


# ---- test harness (same vectors as the MQL5 script)
PASS = FAIL = 0


def T(cond, name):
    global PASS, FAIL
    if cond:
        PASS += 1
    else:
        FAIL += 1
        print("FAIL ", name)


def eq(a, b, eps=1e-9):
    return a is not None and b is not None and abs(a - b) <= eps


def flat(count):
    return [Bar(100.0, 101.0, 99.0, 100.0, i) for i in range(count)]


def set_s(chrono, s, o, h, l, c):
    chrono[len(chrono) - 1 - s] = Bar(o, h, l, c, chrono[len(chrono) - 1 - s].time)


def series(chrono):
    return list(reversed(chrono))


def base_levels():
    return Levels(104.0, 96.0, 94.0, 106.0, True, "OK")


def main():
    # normalisation / volume
    T(eq(round_to_tick(2650.374, 0.01, -1), 2650.37), "U-NORM-01")
    T(eq(round_to_tick(2650.374, 0.01, 1), 2650.38), "U-NORM-02")
    T(eq(norm_price(2650.37, 0.01, 2, -1), 2650.37) and eq(norm_price(2650.37, 0.01, 2, 1), 2650.37), "U-NORM-04/05")
    T(eq(norm_price(4000.0005, 0.001, 3, -1), 4000.000) and eq(norm_price(4000.0005, 0.001, 3, 1), 4000.001), "U-NORM-06/07")
    T(eq(norm_price(1.234, 0.05, 2, -1), 1.20) and eq(norm_price(1.234, 0.05, 2, 1), 1.25), "U-NORM-08/09")
    T(eq(volume_down(0.0199, 0.01), 0.01) and eq(volume_down(0.03, 0.01), 0.03), "U-VOL-03")
    T(eq(calc_risk_lots(10, 650, 0.01, 100, 0.01)[0], 0.01), "U-VOL-04")
    v, why = calc_risk_lots(5, 650, 0.01, 100, 0.01)
    T(v == 0.0 and "BELOW_MIN" in why, "U-VOL-05")
    T(eq(calc_risk_lots(1e6, 1, 0.01, 50, 0.01)[0], 50.0), "U-VOL-06")
    # pivots
    c = flat(14); set_s(c, 3, 100, 110, 99, 100); r = series(c)
    T(is_pivot_high(r, len(r), 3), "U-PIV-01")
    T(find_swing_beyond(r, len(r), 1, True, 105, False, 100, NEAREST_PRICE) is None, "U-PIV-02 not confirmed")
    c = flat(15); set_s(c, 4, 100, 110, 99, 100); r = series(c)
    sp = find_swing_beyond(r, len(r), 1, True, 105, False, 100, NEAREST_PRICE)
    T(sp is not None and eq(sp[0], 110), "U-PIV-03 confirmed")
    c = flat(15); set_s(c, 4, 100, 110, 99, 100); set_s(c, 5, 100, 110, 99, 100); r = series(c)
    T(find_swing_beyond(r, len(r), 1, True, 105, False, 100, NEAREST_PRICE) is None, "U-PIV-04 equal highs")
    # levels
    c = flat(40)
    set_s(c, 34, 100, 106, 99, 100); set_s(c, 27, 100, 101, 94, 100)
    set_s(c, 19, 100, 108, 99, 100); set_s(c, 12, 100, 101, 92, 100)
    r = series(c); n = len(r)
    lv = compute_levels(r, n, 1, 104, 96, 100, NEAREST_PRICE)
    T(lv.valid and eq(lv.p4, 106) and eq(lv.p3, 94), "U-LVL-02 price")
    lv = compute_levels(r, n, 1, 104, 96, 100, NEAREST_TIME)
    T(eq(lv.p4, 108) and eq(lv.p3, 92), "U-LVL-03 time")
    lv = compute_levels(r, n, 1, 110, 96, 100, NEAREST_PRICE)
    T(not lv.valid and lv.why == "P4_MISSING", "U-LVL-04")
    lv = compute_levels(r, n, 1, 104, 96, 10, NEAREST_PRICE)
    T(not lv.valid and eq(lv.p3, 92) and lv.why == "P4_MISSING", "U-LVL-05")
    # sweep
    lv = base_levels()
    c = flat(30); set_s(c, 1, 103.5, 104.8, 102.9, 103.2); r = series(c)
    s = detect_sweep(r, len(r), 1, lv, 4.0, 0.01, 2)
    T(s and s["dir"] == SELL and s["level"] == P1 and eq(s["entry"], 102.89) and eq(s["ref"], 104.8), "F-002")
    set_s(c, 1, 103.5, 104.1, 102.9, 103.2); r = series(c)
    T(detect_sweep(r, len(r), 1, lv, 4.0, 0.01, 2) is None, "U-SWP-02")
    set_s(c, 1, 103.5, 104.8, 102.9, 103.2); r = series(c)
    T(detect_sweep(r, len(r), 1, lv, 1.0, 0.01, 2) is None, "U-SWP-03")
    set_s(c, 1, 104.5, 104.8, 104.0, 104.2); r = series(c)
    T(detect_sweep(r, len(r), 1, lv, 4.0, 0.01, 2) is None, "U-SWP-04")
    set_s(c, 1, 103.0, 104.8, 102.9, 103.4); r = series(c)
    T(detect_sweep(r, len(r), 1, lv, 4.0, 0.01, 2) is None, "U-SWP-05")
    set_s(c, 1, 103.8, 106.6, 103.0, 103.5); r = series(c)
    s = detect_sweep(r, len(r), 1, lv, 8.0, 0.01, 2)
    T(s and s["level"] == P4 and s["also"], "U-SWP-06")
    set_s(c, 1, 96.3, 97.1, 95.2, 96.8); r = series(c)
    s = detect_sweep(r, len(r), 1, lv, 4.0, 0.01, 2)
    T(s and s["dir"] == BUY and s["level"] == P2 and eq(s["entry"], 97.11) and eq(s["ref"], 95.2), "F-003")
    set_s(c, 1, 96.2, 96.9, 93.4, 96.5); r = series(c)
    s = detect_sweep(r, len(r), 1, lv, 8.0, 0.01, 2)
    T(s and s["level"] == P3, "U-SWP-07")
    set_s(c, 1, 103.5, 104.8, 102.9, 103.2); r = series(c)
    T(detect_sweep(r, len(r), 1, lv, 4.0, 0.01, 2, CONFIRMED_PIVOT) is None, "U-SWP-08")
    set_s(c, 10, 100, 106.0, 99, 100); r = series(c)
    s = detect_sweep(r, len(r), 1, lv, 4.0, 0.01, 2, CONFIRMED_PIVOT)
    T(s and eq(s["ref"], 106.0), "U-SWP-09")
    # breakout
    lv_at = [base_levels() for _ in range(8)]
    atr_at = [4.0] * 8

    def bo(setup):
        c = flat(30)
        for (sidx, o, h, l, cl) in setup:
            set_s(c, sidx, o, h, l, cl)
        r = series(c)
        return detect_breakout(r, len(r), 1, lv_at, atr_at, 0.01, 2)

    s = bo([(3, 105.0, 105.8, 104.8, 105.5), (2, 105.5, 107.3, 105.4, 107.0), (1, 106.5, 107.4, 106.3, 107.2)])
    T(s and s["dir"] == BUY and s["level"] == P4 and eq(s["entry"], 107.41) and eq(s["ref"], 106.3), "F-004")
    up = (107.5, 108.0, 107.0, 107.8)
    s = bo([(6, 105.0, 105.8, 104.8, 105.5), (5, 105.5, 107.3, 105.4, 107.0), (4,) + up, (3,) + up, (2,) + up, (1, 106.8, 107.6, 106.4, 107.3)])
    T(s and eq(s["ref"], 106.4) and s["b"] == 5, "U-BRK-03 4th candle")
    s = bo([(7, 105.0, 105.8, 104.8, 105.5), (6, 105.5, 107.3, 105.4, 107.0), (5,) + up, (4,) + up, (3,) + up, (2,) + up, (1, 106.8, 107.6, 106.4, 107.3)])
    T(s is None, "F-006 5th candle")
    s = bo([(4, 105.0, 105.8, 104.8, 105.5), (3, 105.5, 107.3, 105.4, 107.0), (2, 106.5, 107.2, 106.2, 107.0), (1, 106.6, 107.4, 106.3, 107.2)])
    T(s is None, "U-BRK-07 consumed")
    s = bo([(3, 105.0, 105.8, 104.8, 105.5), (2, 105.5, 107.3, 105.4, 107.0), (1, 105.6, 107.4, 105.2, 107.2)])
    T(s is None, "U-BRK-05 deep")
    s = bo([(3, 105.0, 105.8, 104.8, 105.5), (2, 105.5, 107.3, 105.4, 107.0), (1, 107.2, 107.4, 106.3, 106.5)])
    T(s is None, "U-BRK-06 bearish")
    s = bo([(3, 105.0, 105.8, 104.8, 105.5), (2, 105.5, 106.6, 105.4, 106.3), (1, 106.5, 107.4, 106.3, 107.2)])
    T(s is None, "U-BRK-02 weak close")
    s = bo([(3, 95.0, 95.2, 94.2, 94.5), (2, 94.5, 94.6, 92.7, 93.0), (1, 93.5, 93.8, 92.6, 92.8)])
    T(s and s["dir"] == SELL and s["level"] == P3 and eq(s["entry"], 92.59) and eq(s["ref"], 93.8), "F-005")
    # stops
    st = compute_stops(BUY, 97.11, 95.2, 4.0, 0.01, 2)
    T(st and eq(st["buf"], 0.2) and eq(st["sl"], 95.00) and eq(st["tp"], 101.33) and eq(st["rr"], 2.0, 1e-6), "SL-001")
    st = compute_stops(SELL, 102.89, 104.8, 4.0, 0.01, 2)
    T(st and eq(st["sl"], 105.00) and eq(st["tp"], 98.67) and eq(st["rr"], 2.0, 1e-6), "SL-002")
    st = compute_stops(BUY, 97.11, 95.2, 0.2, 0.01, 2)
    T(st and eq(st["buf"], 0.02) and eq(st["sl"], 95.18), "SL-003")
    st = compute_stops(BUY, 97.11, 95.2, 0.5, 0.01, 2)
    T(st and eq(st["sl"], 95.17), "SL-004a")
    st = compute_stops(SELL, 102.89, 104.8, 0.5, 0.01, 2)
    T(st and eq(st["sl"], 104.83), "SL-004b")
    T(compute_stops(BUY, 97.11, 97.2, 4.0, 0.01, 2) is None, "U-SL-05")
    st = compute_stops(BUY, 4000.501, 3998.2, 5.0, 0.001, 3)
    T(st and eq(st["sl"], 3997.950) and eq(st["tp"], 4005.603), "U-SL-07")
    T(sl_within_approved(BUY, 95.0, 95.0, 0.01) and sl_within_approved(BUY, 95.5, 95.0, 0.01), "POS-002a")
    T(not sl_within_approved(BUY, 94.5, 95.0, 0.01) and not sl_within_approved(BUY, 0.0, 95.0, 0.01), "POS-002b")
    T(sl_within_approved(SELL, 104.5, 105.0, 0.01) and not sl_within_approved(SELL, 105.5, 105.0, 0.01), "POS-004")
    # touch
    ticks = [(1000, 100.5, 100.7), (2000, 100.2, 100.4), (3000, 99.99, 100.19), (4000, 100.3, 100.5)]
    ok, ms, px = find_touch(ticks, BUY, 100.0, 0, 0.01)
    T(ok and ms == 3000 and eq(px, 99.99), "SI-001")
    T(not find_touch(ticks, BUY, 100.0, 3500, 0.01)[0], "SI-003")
    T(find_touch(ticks, BUY, 100.2, 0, 0.01)[1] == 2000, "U-TCH-02")
    ok, ms, px = find_touch(ticks, SELL, 100.7, 0, 0.01)
    T(ok and ms == 1000, "SI-002")
    T(not find_touch(ticks, SELL, 100.71, 0, 0.01)[0], "U-TCH-03")
    print(f"REFERENCE MODEL: {PASS} passed, {FAIL} failed")
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
