# Trading Helper

A small tool that tells you what simple buy/sell rules say right now, and how
those rules would have performed in the past (backtest).

**Not financial advice.** No tool can reliably predict the market. Practice on
TradingView **Paper Trading** before using real money.

## Setup (once)

1. Install Python 3.10+ from https://www.python.org/downloads/
   (on Windows, tick "Add Python to PATH").
2. Open a terminal in this folder and run:

       pip install -r requirements.txt

## Run

    python helper.py                 # SPY, AAPL, TSLA
    python helper.py MSFT NVDA QQQ   # your own tickers
    python helper.py --years 10 SPY  # longer history
    python helper.py --demo          # fake data, no internet needed

## The rules

- **Buy / hold** when the 20-day average is above the 50-day average
  (uptrend) and RSI is below 70.
- **Sell / stay out** otherwise.
- Backtest trades on the next day's price and charges 0.1% per trade.

Edit the numbers at the top of `helper.py` to try other settings.

## Reading the result

The report compares the strategy with simply buying and holding. If it does
**not beat buy & hold**, the rules aren't adding value. That is common, and
it's useful to know before risking money.
