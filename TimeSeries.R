install.packages(c("tidyverse"))
install.packages(c("jsonlite"))
install.packages(c("tseries"))
install.packages(c("lmtest"))
install.packages(c("dynlm"))
install.packages(c("gridExtra"))
install.packages(c("corrplot"))
install.packages(c("strucchange"))
install.packages(c("vars"))
install.packages(c("sandwich"))

library(sandwich)
library(tidyverse)
library(jsonlite)
library(tseries)
library(lmtest)
library(dynlm)
library(gridExtra)
library(corrplot)
library(strucchange)
library(vars)

# 1. Load exchange-rate data
fx <- read_csv(
  "results_20260424.csv",
  col_names = c("Date", "ExRate")
) %>%
  mutate(
    Date = as.Date(Date),
    ExRate = as.numeric(ExRate)
  ) %>%
  arrange(Date)

# 2. Load IODA data
ioda <- read_csv("ioda-iran-(islamic-republic-of)-26-01-01-01-00-normalized (1).csv") %>%
  mutate(
    DateTime = as.POSIXct(`Time (UTC)`, tz = "UTC"),
    Date = as.Date(DateTime)
  )

# 3. Convert IODA data to daily average
ioda_daily <- ioda %>%
  group_by(Date) %>%
  summarise(
    ActiveProbe = mean(`Active Probing (#/24s Up)`, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Loss = 100 - ActiveProbe
  )

# 4. Merge datasets
df <- fx %>%
  inner_join(ioda_daily, by = "Date") %>%
  filter(
    Date >= as.Date("2026-01-01"),
    Date <= as.Date("2026-03-31")
  ) %>%
  arrange(Date)

summary(df)

#Correlation Heatmap

corr_data <- df_diff %>%
  dplyr::select(d_log_ExRate, d_Loss)

corr_matrix <- cor(corr_data)

corrplot(
  corr_matrix,
  method = "color",
  addCoef.col = "black",
  number.cex = 1.2
)

ggplot(df, aes(Date, ExRate)) +
  geom_line(linewidth = 1) +
  
  geom_vline(
    xintercept = as.Date("2026-01-15"),
    color = "red",
    linetype = "dashed",
    linewidth = 1
  ) +
  
  annotate(
    "text",
    x = as.Date("2026-01-15"),
    y = max(df$ExRate),
    label = "Blackout Begins",
    angle = 90,
    vjust = -0.5,
    color = "red"
  ) +
  
  labs(
    title = "USD/Tuman Exchange Rate with Blackout Shock",
    x = "Date",
    y = "USD/Tuman"
  ) +
  
  theme_minimal()

# ADF TESTS: ORIGINAL SERIES


adf_exrate <- adf.test(df$ExRate)
adf_loss <- adf.test(df$Loss)

adf_exrate
adf_loss

# 5. Transform variables
df_diff <- df %>%
  mutate(
    d_log_ExRate = c(NA, diff(log(ExRate))),
    d_Loss = c(NA, diff(Loss))
  ) %>%
  drop_na()

# 6. Visualize original series
p1 <- ggplot(df, aes(Date, ExRate)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Original USD/Toman Rate Series",
    x = "Date",
    y = "USD/Toman"
  ) +
  theme_minimal()

p2 <- ggplot(df, aes(Date, Loss)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Original Internet Loss Series",
    x = "Date",
    y = "Internet Loss (%)"
  ) +
  theme_minimal()

grid.arrange(p1, p2, ncol = 1)

# 7. Visualize differenced series
p3 <- ggplot(df_diff, aes(Date, d_log_ExRate)) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Differenced Log Exchange Rate",
    x = "Date",
    y = "Log Returns"
  ) +
  theme_minimal()

p4 <- ggplot(df_diff, aes(Date, d_Loss)) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Differenced Internet Loss",
    x = "Date",
    y = "Change in Internet Loss"
  ) +
  theme_minimal()

grid.arrange(p3, p4, ncol = 1)

# 8. ADF stationarity tests

print("ADF TESTS: DIFFERENCED SERIES")
adf.test(df_diff$d_log_ExRate)
adf.test(df_diff$d_Loss)

# 9. Correlation and OLS
cor(df_diff$d_log_ExRate, df_diff$d_Loss)

ols_model <- lm(d_log_ExRate ~ d_Loss, data = df_diff)
summary(ols_model)


# 9.1 OLS with robust standard errors

coeftest(
  ols_model,
  vcov = vcovHC(ols_model, type = "HC1")
)

# 9.2 OLS fitted values

df_diff <- df_diff %>%
  mutate(
    ols_fitted = fitted(ols_model),
    ols_residuals = residuals(ols_model)
  )

# 9.3 Scatter plot with regression line

ggplot(df_diff, aes(x = d_Loss, y = d_log_ExRate)) +
  geom_point() +
  geom_smooth(method = "lm", se = TRUE) +
  labs(
    title = "OLS Relationship Between Internet Loss and Exchange Rate Returns",
    x = "Change in Internet Loss",
    y = "Change in Log Exchange Rate"
  ) +
  theme_minimal()

# 9.4 Actual vs fitted values

ggplot(df_diff, aes(x = Date)) +
  geom_line(aes(y = d_log_ExRate), linewidth = 1) +
  geom_line(aes(y = ols_fitted), linetype = "dashed", linewidth = 1) +
  labs(
    title = "Actual vs Fitted Exchange Rate Returns from OLS",
    x = "Date",
    y = "Exchange Rate Log Returns"
  ) +
  theme_minimal()

# 9.5 OLS residual plot

ggplot(df_diff, aes(x = Date, y = ols_residuals)) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "OLS Residuals Over Time",
    x = "Date",
    y = "OLS Residuals"
  ) +
  theme_minimal()

# 9.6 OLS diagnostic tests
# Autocorrelation test
bgtest(ols_model, order = 2)

# Heteroskedasticity test
bptest(ols_model)

# Normality test
jarque.bera.test(residuals(ols_model))

# 10. Granger causality
grangertest(d_log_ExRate ~ d_Loss, order = 2, data = df_diff)

# 11. ARDL model
cor(
  df_diff$d_log_ExRate[-1],
  df_diff$d_log_ExRate[-nrow(df_diff)]
)
df_ardl <- df_diff %>%
  mutate(
    lag_ExRate = lag(d_log_ExRate, 1),
    lag_Loss = lag(d_Loss, 1)
  ) %>%
  drop_na()

ardl_test <- lm(
  d_log_ExRate ~ lag_ExRate + d_Loss + lag_Loss,
  data = df_ardl
)

summary(ardl_test)
ardl_model <- dynlm(
  d_log_ExRate ~ L(d_log_ExRate, 1) + d_Loss + L(d_Loss, 1),
  data = df_diff
)

summary(ardl_model)

grangertest(
  d_log_ExRate ~ d_Loss,
  order = 1,
  data = df_diff
)

grangertest(
  d_log_ExRate ~ d_Loss,
  order = 3,
  data = df_diff
)

# 12. Diagnostic test

break_model <- breakpoints(
  d_log_ExRate ~ d_Loss,
  data = df_diff
)

summary(break_model)

plot(break_model)

break_dates <- df_diff$Date[break_model$breakpoints]
break_dates

#  RESIDUAL DIAGNOSTICS

bgtest(ardl_model, order = 2)

bptest(ardl_model)

jarque.bera.test(residuals(ardl_model))

# RESIDUAL VISUALIZATION

plot(
  residuals(ardl_model),
  type = "l",
  main = "Residuals from ARDL Model",
  xlab = "Observation",
  ylab = "Residuals"
)

abline(h = 0, lty = 2)

