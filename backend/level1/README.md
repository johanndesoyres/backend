# Intro

We're trying to model the expected delivery date for online orders shipped through various shipping carriers.

# Level 1

Each shipping carrier has specific delivery promises (in days).
The online retailers assigns a shipping date and a carrier to each order.

We first want to compute a list of expected delivery dates for some packages.

# Execution

If you want to run the code just run the following command in the current directory :

```
$ iex -S mix
iex> Main.compute_expected_delivery_dates
```
