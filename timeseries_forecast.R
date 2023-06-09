
# Plot of Timeseries Forecast based on Hierarchical Bayesian Vector Autoregression Model 

# load libraries
set.seed(111)
library(BVAR)
library(dplyr)
library(ggplot2)

########## Data from BVAR pkg
# info ?fred_qd 
x <- fred_qd[1:243, c("GDPC1", "PCECC96", "GPDIC1", "HOANBS", "GDPCTPI", "FEDFUNDS")]
x <- fred_transform(x, codes = c(4, 4, 4, 4, 4, 1))

########## Model 
# Minnesota prior
mn <- bv_minnesota(lambda = bv_lambda(mode = 0.2, sd = 0.4, min = 0.0001, max = 5),
                   alpha = bv_alpha(mode = 2), var = 1e07)

# Dummy prior settings
soc <- bv_soc(mode = 1, sd = 1, min = 1e-04, max = 50)
sur <- bv_sur(mode = 1, sd = 1, min = 1e-04, max = 50)

# Prior settings
priors <- bv_priors(hyper = "auto", mn = mn, soc = soc, sur = sur)

# Metropolis-Hastings settings
mh <- bv_metropolis(scale_hess = c(0.05, 0.0001, 0.0001),
                    adjust_acc = TRUE, acc_lower = 0.25, acc_upper = 0.45)

# Run the sampler
run <- bvar(x, lags = 5, n_draw = 50000, n_burn = 25000, n_thin = 1,
            priors = priors, mh = mh, verbose = TRUE)

# Model Predictions
preds <- predict(run, conf_bands = c(0.05, 0.16))

# collect past/future data for visualisation
# past data
df_data <- data.frame(date = attributes(preds$data[208:238,6])$names, 
                 value = preds$data[208:238,6]) %>% 
    arrange(date) %>% 
    mutate(ind = -rev(seq(0, 30))) %>% # set a fake x axis 
    select(value, ind) %>%
    mutate(period = "past")

# future data (predictions)
df_preds <- data.frame(value = preds$quants[,,6][3,], 
                       lower = preds$quants[,,6][1,],
                       upper = preds$quants[,,6][5,],
                       ind = seq(0.1, length(preds$quants[,,6][3,]))) %>%
    mutate(period  = "future")

########### Create Plot
y_text <- 5.5
size_all <- 1
ggplot() +
    geom_line(data = df_data, aes(x = ind, y = value), lwd = 1) +
    geom_line(data = df_preds, aes(x = ind, y = value), col = "orange", lwd = 1) +
    geom_ribbon(data = df_preds, aes(x = ind, ymin = lower, ymax = upper, linetype = NA), 
                alpha = 0.3, fill = "orange") +
    theme_classic(12) +
    labs(x = "Years",  y = "Change in GDP (%)") +
    geom_vline(xintercept = 0, col = "grey", linetype = "dashed", lwd = 1) +
    ylim(c(0, 6)) +
    ggtitle("Timeseries Forecast", 
            subtitle = "Predicted Change in GPD (orange) with 90% Credible Bands") +
    theme(plot.title = element_text(colour = "black",
                                    size = 14,
                                    face = "bold")) +
    annotate("text", x = -15, y = y_text, label = "Past", size = 6) +
    annotate("text", x = 7.5, y = y_text, label = "Forecast", size = 6) +
    annotate("segment", x = c(-25, -13, 2, 11), xend = c(-17, -5, 4, 13), y = y_text, yend = y_text,
             colour = "black", linewidth = size_all) +
    annotate("segment", x = c(-25, -5, 2, 13), xend = c(-25, -5, 2, 13), 
             y = y_text + c(-0.2, 0.2, -0.2, 0.2), yend = y_text + rev(c(-0.2, 0.2, -0.2, 0.2)),
             colour = "black", linewidth = size_all) 





