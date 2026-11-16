# ============================================================
# BUAN6356 Group Project - Logistic Regression
#   (1) Split the data into training and test data, run logistic regression, display results (Ethan)
#   (2) Interpretation of significance and coefficients (Ethan)
#   (3) Accuracy on the training & test data -> Jeremiah, using the files saved at the end
#
# Team decisions used here (see README.md, section 4):
#   - Outcome: dv_not_on_time (main). dv_late_only is run as a robustness check.
#   - Split by TIME, not at random: train = orders entered before 2022-01-01, test = 2022 onward.
#     (The lecture example uses a random 60/40 split; the proposal commits us to a time split.)
#   - Size: log_ordered_qty + log_unit_price (log_line_value left out: it is ~ their sum, r = 0.99)
#   - Timing: entry_to_po + days_left_at_po (planned_lead left out: planned_lead = entry_to_po + days_left_at_po exactly)
#   - slack kept in the main model; a model without slack is run as a leakage check
#
# Input:  output/05_model_data.rds (27,950 rows, from 05_preprocess.R)
# Output: output/07_* files (listed at the bottom)
# Base R only (no packages needed)
# ============================================================

setwd("D:/SHARED SYNCTHING/UTD/Fall 2026/BUAN 6356 business analytics with r/Healthcare supply chain project/Predicting-Late-Deliveries-of-Global-Health-Commodities/share_for_team/")   # <- CHANGE to the folder where you saved these files
m <- readRDS("output/05_model_data.rds")

# ---- (1a) Split the data into training and test data ----
# All lines of an order share one entry date, so this never splits an order.
cutoff_date <- as.Date("2022-01-01")
train <- m$order_entry_date < cutoff_date
train.df <- m[train, ]
test.df  <- m[!train, ]

split_tbl <- data.frame(
  Set          = c("Training", "Test"),
  Orders_from  = c(format(min(train.df$order_entry_date)), format(min(test.df$order_entry_date))),
  Orders_to    = c(format(max(train.df$order_entry_date)), format(max(test.df$order_entry_date))),
  Lines        = c(nrow(train.df), nrow(test.df)),
  Share        = round(c(nrow(train.df), nrow(test.df)) / nrow(m), 3),
  Not_On_Time  = round(c(mean(train.df$dv_not_on_time), mean(test.df$dv_not_on_time)), 3),
  Late_Only    = round(c(mean(train.df$dv_late_only),   mean(test.df$dv_late_only)), 3))
split_tbl     # expected: 23,346 train (11.6% Not On Time) / 4,604 test (10.3%)

# ---- (1b) Run logistic regression ----
# use glm() (general linear model) with family = "binomial" to fit a logistic regression
# Categorical variables are factors; the most common group is the reference level (set in 05_preprocess.R).
predictors <- "log_ordered_qty + log_unit_price + log_lines_per_order +
               request_gap + usaid_approval_days + po_processing_days +
               entry_to_po + days_left_at_po + slack +
               order_type + tlp + transport + task_order + product + country +
               framework + funding + vendor_inco + dest_inco"

logit.reg <- glm(as.formula(paste("dv_not_on_time ~", predictors)),
                 data = train.df, family = "binomial")

# ---- (1c) Display the results ----
summary(logit.reg)
sum(is.na(coef(logit.reg)))   # expected 0 (no variable dropped by R)

# Coefficient table with odds ratios, e^b (lecture: odds ratio = e^b1)
coef_table <- function(fit) {
  s <- summary(fit)$coefficients
  data.frame(Term       = rownames(s),
             Estimate   = s[, 1],
             Std.Error  = s[, 2],
             z.value    = s[, 3],
             p.value    = s[, 4],
             Odds.Ratio = exp(s[, 1]),
             Pct.Change.in.Odds = (exp(s[, 1]) - 1) * 100,
             Signif     = cut(s[, 4], c(-Inf, 0.001, 0.01, 0.05, 0.1, Inf),
                              labels = c("***", "**", "*", ".", ""), right = FALSE),
             row.names = NULL, check.names = FALSE)
}
coefs_main <- coef_table(logit.reg)
print(format(coefs_main, digits = 3), row.names = FALSE)

# ---- (2) Interpretation helpers ----
# Durations are in days, so one day is a tiny change. The odds ratio for 30 days = e^(30*b).
# Size variables are log10(x + 1), so +1 on the log scale = about 10 times the original value.
#   Odds ratio for a 10x larger value = e^b (one unit of log10).
day_vars <- c("request_gap", "usaid_approval_days", "po_processing_days",
              "entry_to_po", "days_left_at_po", "slack")
log_vars <- c("log_ordered_qty", "log_unit_price", "log_lines_per_order")
b <- coef(logit.reg)
interp_tbl <- rbind(
  data.frame(Term = day_vars, Change = "+30 days",
             Odds.Ratio = exp(30 * b[day_vars]), p.value = coefs_main$p.value[match(day_vars, coefs_main$Term)]),
  data.frame(Term = log_vars, Change = "10x larger",
             Odds.Ratio = exp(b[log_vars]),      p.value = coefs_main$p.value[match(log_vars, coefs_main$Term)]))
interp_tbl$Pct.Change.in.Odds <- (interp_tbl$Odds.Ratio - 1) * 100
rownames(interp_tbl) <- NULL
print(format(interp_tbl, digits = 3), row.names = FALSE)

# Overlap found in this step: every Distribution Order has vendor incoterm "Unknown"
# (warehouse shipments have no supplier incoterm), and almost every "Unknown" is a Distribution Order.
table(train.df$order_type, train.df$vendor_inco)
# So the two dummies are nearly the same column. Their separate coefficients are unstable
# (large standard errors, opposite signs), but their SUM is the effect of a typical distribution order.
# Team decision: keep both and interpret the combined effect.
combo <- c("order_typeDistribution Order", "vendor_incoUnknown")
combo_b  <- sum(b[combo])
combo_se <- sqrt(sum(vcov(logit.reg)[combo, combo]))
combo_tbl <- data.frame(Term = "Distribution Order + vendor incoterm Unknown (combined)",
                        Estimate = combo_b, Std.Error = combo_se,
                        p.value = 2 * pnorm(-abs(combo_b / combo_se)),
                        Odds.Ratio = exp(combo_b),
                        OR_95CI_low = exp(combo_b - 1.96 * combo_se),
                        OR_95CI_high = exp(combo_b + 1.96 * combo_se))
combo_tbl

# Which groups of variables matter overall? (likelihood-ratio test for each variable, all levels together)
lr_tests <- drop1(logit.reg, test = "LRT")
lr_tests

# ---- Robustness check 1: model without slack (possible leakage) ----
logit.noslack <- update(logit.reg, . ~ . - slack)
coefs_noslack <- coef_table(logit.noslack)

# ---- Robustness check 2: late-only outcome (dv_late_only) ----
logit.late <- glm(as.formula(paste("dv_late_only ~", predictors)),
                  data = train.df, family = "binomial")
coefs_late <- coef_table(logit.late)

# Side-by-side: same sign and significance across the three models?
robust_tbl <- data.frame(
  Term           = coefs_main$Term,
  Main_Estimate  = coefs_main$Estimate,
  Main_p         = coefs_main$p.value,
  NoSlack_Estimate = coefs_noslack$Estimate[match(coefs_main$Term, coefs_noslack$Term)],
  NoSlack_p        = coefs_noslack$p.value[match(coefs_main$Term, coefs_noslack$Term)],
  LateOnly_Estimate = coefs_late$Estimate,
  LateOnly_p        = coefs_late$p.value)
robust_tbl$Same_Sign_LateOnly <- sign(robust_tbl$Main_Estimate) == sign(robust_tbl$LateOnly_Estimate)
print(format(robust_tbl, digits = 3), row.names = FALSE)

fit_tbl <- data.frame(
  Model    = c("Main (Not On Time)", "Without slack", "Late only (DV B)"),
  Outcome  = c("dv_not_on_time", "dv_not_on_time", "dv_late_only"),
  Coefficients = c(length(coef(logit.reg)), length(coef(logit.noslack)), length(coef(logit.late))),
  AIC      = c(AIC(logit.reg), AIC(logit.noslack), AIC(logit.late)),
  Signif_at_0.05 = c(sum(coefs_main$p.value[-1] < 0.05), sum(coefs_noslack$p.value[-1] < 0.05),
                     sum(coefs_late$p.value[-1] < 0.05)))
fit_tbl

# ---- Hand-off for (3) Accuracy (Jeremiah) ----
# Predicted probabilities of Not On Time, i.e., P(class = 1)
# use predict() with type = "response" to compute predicted probabilities
train.df$prob_not_on_time <- predict(logit.reg, train.df, type = "response")
test.df$prob_not_on_time  <- predict(logit.reg, test.df,  type = "response")
train.df$prob_late_only   <- predict(logit.late, train.df, type = "response")
test.df$prob_late_only    <- predict(logit.late, test.df,  type = "response")
train.df$prob_no_slack    <- predict(logit.noslack, train.df, type = "response")
test.df$prob_no_slack     <- predict(logit.noslack, test.df,  type = "response")
summary(test.df$prob_not_on_time)

# ---- Save ----
dir.create("output", showWarnings = FALSE)
write.csv(split_tbl,   "output/07_split_summary.csv",       row.names = FALSE)
write.csv(coefs_main,  "output/07_coefficients_main.csv",   row.names = FALSE)
write.csv(interp_tbl,  "output/07_interpretation_scaled.csv", row.names = FALSE)
write.csv(combo_tbl,   "output/07_distribution_order_combined.csv", row.names = FALSE)
write.csv(data.frame(Term = rownames(lr_tests), lr_tests, row.names = NULL, check.names = FALSE),
          "output/07_variable_tests.csv", row.names = FALSE)
write.csv(robust_tbl,  "output/07_robustness_coefficients.csv", row.names = FALSE)
write.csv(fit_tbl,     "output/07_model_fit.csv",           row.names = FALSE)
id_prob <- c("order_number", "order_entry_date", "dv_not_on_time", "dv_late_only",
             "prob_not_on_time", "prob_late_only", "prob_no_slack")
write.csv(train.df[, id_prob], "output/07_train_predictions.csv", row.names = FALSE)
write.csv(test.df[, id_prob],  "output/07_test_predictions.csv",  row.names = FALSE)
saveRDS(train.df, "output/07_train.rds")   # training data (with predicted probabilities)
saveRDS(test.df,  "output/07_test.rds")    # test data (with predicted probabilities)
slim <- function(fit) { fit$data <- NULL; fit$model <- NULL; fit }   # smaller file; predict() and summary() still work
saveRDS(list(main = slim(logit.reg), no_slack = slim(logit.noslack), late_only = slim(logit.late)),
        "output/07_logit_models.rds", compress = "xz")      # fitted models: readRDS(...)$main, then predict(..., type = "response")
capture.output(summary(logit.reg), file = "output/07_summary_main.txt")
capture.output(summary(logit.late), file = "output/07_summary_late_only.txt")
capture.output(summary(logit.noslack), file = "output/07_summary_no_slack.txt")

# ---- Odds-ratio chart for the slides (numeric predictors, scaled) ----
png("output/07_odds_ratios.png", width = 1600, height = 900, res = 200)
labels <- c(request_gap = "Promise vs. request (+30 d)", usaid_approval_days = "USAID approval time (+30 d)",
            po_processing_days = "PO processing time (+30 d)", entry_to_po = "Entry to PO (+30 d)",
            days_left_at_po = "Days left at PO (+30 d)", slack = "Supplier slack (+30 d)",
            log_ordered_qty = "Ordered quantity (10x)", log_unit_price = "Unit price (10x)",
            log_lines_per_order = "Lines per order (10x)")
o <- order(interp_tbl$Odds.Ratio)
par(mar = c(4, 14, 2, 2))
cols <- ifelse(interp_tbl$p.value[o] < 0.05, ifelse(interp_tbl$Odds.Ratio[o] > 1, "#C0504D", "#4F81BD"), "grey70")
barplot(interp_tbl$Pct.Change.in.Odds[o], names.arg = labels[interp_tbl$Term[o]], horiz = TRUE, las = 1,
        col = cols, border = NA, xlab = "% change in odds of Not On Time", cex.names = 0.8, xlim = c(-55, 20),
        main = "Odds ratios, numeric predictors (grey = not significant at 0.05)", cex.main = 0.9)
abline(v = 0)
dev.off()
