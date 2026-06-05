
**The Digital Blackout: An Econometric Analysis of Internet Connectivity Shocks and Exchange Rate Volatility in Iran**

## Project Description

This project investigates the relationship between internet connectivity disruptions and exchange-rate dynamics in Iran during the nationwide internet shutdowns of January–March 2026. The study combines internet connectivity data from the Internet Outage Detection and Analysis (IODA) platform with free-market USD/Toman exchange-rate data obtained from Bonbast.

The objective is to examine whether internet shutdowns function as information shocks that influence exchange-rate behavior.

## Research Question

Does internet connectivity loss influence exchange-rate dynamics in Iran?

## Data Sources

### Exchange Rate Data

Source: Bonbast
Description: Daily free-market USD/Toman exchange-rate observations.

### Internet Connectivity Data

Source: Internet Outage Detection and Analysis (IODA) Platform
Description: Network telemetry data based on Active Probing measurements.

## Reproducibility

This project uses the `renv` package to manage package dependencies. The file `renv.lock` contains the package versions used during the analysis.

To reproduce the environment:

```r
install.packages("renv")
renv::restore()
```

After restoring the environment, run `analysis.R` to reproduce the empirical results.

## Software Requirements


The analysis was conducted in R.

Required packages:

* tidyverse
* jsonlite
* tseries
* lmtest
* dynlm
* gridExtra
* corrplot
* strucchange
* vars

## Project Structure

* `results_20260424.csv` – Exchange-rate data
* `ioda-iran.csv` – IODA internet connectivity data
* `analysis.R` – Main R script
* `Project_Report.pdf` – Final report
* renv.lock

## Methodology

The project applies several econometric techniques:

1. Descriptive analysis
2. Augmented Dickey-Fuller (ADF) stationarity testing
3. Ordinary Least Squares (OLS) regression
4. Diagnostic testing

   * Breusch-Godfrey Test
   * Breusch-Pagan Test
   * Jarque-Bera Test
5. Granger causality analysis
6. Autoregressive Distributed Lag (ARDL) modelling
7. Structural break analysis

## Main Findings

* No statistically significant contemporaneous relationship was found between internet-loss changes and exchange-rate returns using OLS.
* Granger causality tests indicate that internet connectivity shocks contain predictive information regarding future exchange-rate movements.
* ARDL results reveal a statistically significant lagged effect of internet-loss shocks on exchange-rate returns.
* Structural break analysis provides no strong evidence of a distinct regime shift during the sample period.

Overall, the findings suggest that internet shutdowns affect exchange-rate dynamics through delayed information and expectation channels rather than through immediate market reactions.

## References

Key references used in the project include:

* Dickey & Fuller (1979)
* Granger (1969)
* Pesaran, Shin & Smith (2001)
* Evans & Lyons (2002)
* Mankiw & Reis (2002)
* Mattes (2012)
* Shahhosseini (2021)
* OECD (2019)
* Jahromi & Jaskolka (2026)

## Disclaimer

This project was prepared for academic purposes as part of the Econometrics course at the University of Warsaw. The findings should be interpreted within the limitations discussed in the report, including the short sample period, the presence of concurrent political and military events, and constraints related to data availability and transparency.
