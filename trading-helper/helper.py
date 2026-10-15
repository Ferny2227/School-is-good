"""Simple buy/sell signal helper with a backtester.

NOT financial advice. It shows what simple rules say now and how they would
have done in the past. Past results do not predict future results.

Usage:
    python helper.py                      # SPY, AAPL, TSLA
    python helper.py MSFT NVDA            # your own tickers
    python helper.py --years 10 SPY       # longer history
    python helper.py --demo               # fake data, no internet needed
"""
import argparse

import numpy as np
import pandas as pd

DEFAULT_TICKERS = ["SPY", "AAPL", "TSLA"]
FAST, SLOW = 20, 50          # moving-average windows (days)
RSI_LEN, RSI_LOW, RSI_HIGH = 14, 30, 70
COST = 0.001                 # 0.1% assumed cost per trade (spread/fees)


def get_prices(ticker, years):
    import yfinance as yf

    df = yf.download(ticker, period=f"{years}y", auto_adjust=True, progress=False)
    if df.empty:
        raise ValueError(f"No data for {ticker}")
    close = df["Close"]
    if isinstance(close, pd.DataFrame):  # newer yfinance returns 1-col frame
        close = close.iloc[:, 0]
    return close.dropna().astype(float)


def demo_prices(seed, years):
    rng = np.random.default_rng(seed)
    n = int(252 * years)
    returns = rng.normal(0.0004, 0.015, n)
    idx = pd.bdate_range(end=pd.Timestamp.today().normalize(), periods=n)
    return pd.Series(100 * np.exp(np.cumsum(returns)), index=idx)


def rsi(close, length=RSI_LEN):
    delta = close.diff()
    gain = delta.clip(lower=0).ewm(alpha=1 / length, adjust=False).mean()
    loss = (-delta.clip(upper=0)).ewm(alpha=1 / length, adjust=False).mean()
    return 100 - 100 / (1 + gain / loss.replace(0, np.nan))


def add_signals(close):
    """Return a frame with indicators and a 0/1 'hold' position.

    Rule: be in the stock when the fast average is above the slow average
    (uptrend) AND RSI is not overbought. Otherwise stay in cash.
    """
    df = pd.DataFrame({"close": close})
    df["fast"] = close.rolling(FAST).mean()
    df["slow"] = close.rolling(SLOW).mean()
    df["rsi"] = rsi(close)
    uptrend = df["fast"] > df["slow"]
    df["target"] = (uptrend & (df["rsi"] < RSI_HIGH)).astype(int)
    df.loc[df["slow"].isna(), "target"] = 0
    return df


def backtest(df):
    # Trade on the NEXT day's price: today's signal is unknown until the close.
    position = df["target"].shift(1).fillna(0)
    daily = df["close"].pct_change().fillna(0)
    trades = position.diff().abs().fillna(0)
    strat = position * daily - trades * COST
    return strat, daily, int(trades.sum())


def stats(returns):
    equity = (1 + returns).cumprod()
    total = equity.iloc[-1] - 1
    years = max(len(returns) / 252, 1e-9)
    yearly = equity.iloc[-1] ** (1 / years) - 1
    drawdown = (equity / equity.cummax() - 1).min()
    return total, yearly, drawdown


def describe_signal(df):
    last, prev = df.iloc[-1], df.iloc[-2]
    if last["target"] == 1 and prev["target"] == 0:
        return "BUY  (uptrend just started)"
    if last["target"] == 0 and prev["target"] == 1:
        return "SELL (uptrend ended or RSI overbought)"
    if last["target"] == 1:
        return "HOLD (stay in; uptrend continues)"
    return "STAY OUT (no uptrend)"


def report(ticker, close):
    df = add_signals(close)
    strat, buyhold, n_trades = backtest(df)
    s_tot, s_yr, s_dd = stats(strat)
    b_tot, b_yr, b_dd = stats(buyhold)
    last = df.iloc[-1]
    verdict = "beat" if s_tot > b_tot else "did NOT beat"
    print(f"\n=== {ticker} ===")
    print(f"Price {last['close']:.2f} | RSI {last['rsi']:.0f} | "
          f"{FAST}d avg {last['fast']:.2f} | {SLOW}d avg {last['slow']:.2f}")
    print(f"Signal today: {describe_signal(df)}")
    print(f"Backtest over {len(df) / 252:.1f} years, {n_trades} trades:")
    print(f"  Strategy  : {s_tot:+.0%} total, {s_yr:+.1%}/yr, worst drop {s_dd:.0%}")
    print(f"  Buy & hold: {b_tot:+.0%} total, {b_yr:+.1%}/yr, worst drop {b_dd:.0%}")
    print(f"  -> The strategy {verdict} simply buying and holding.")


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("tickers", nargs="*", default=DEFAULT_TICKERS)
    p.add_argument("--years", type=int, default=5)
    p.add_argument("--demo", action="store_true", help="use fake data (offline)")
    args = p.parse_args()

    for i, t in enumerate(args.tickers):
        t = t.upper()
        try:
            close = demo_prices(i, args.years) if args.demo else get_prices(t, args.years)
            report(t, close)
        except Exception as e:  # keep going if one ticker fails
            print(f"\n=== {t} ===\nCould not load data: {e}")
    print("\nNot financial advice. Past results do not predict the future. "
          "Practice on Paper Trading first.")


if __name__ == "__main__":
    main()
