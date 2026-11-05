# ============================================================
# BUAN6356 Group Project - Step D: Outlier detection with box plots
#   1) Box plots of the 11 numeric IVs (raw scale)
#   2) Box-plot (Tukey 1.5 x IQR) outlier counts per variable
#   3) Rule-based check for values that cannot be real (data errors)
#   4) Box plots again after setting those error values to NA (proposal only)
# This script only DETECTS and COMPARES. It does not overwrite the analysis data.
# Final pre-processing decisions are made in the next step.
# Base R only (no packages needed)
# ============================================================

setwd("C:/BIZANwR")   # <- CHANGE to the folder where you saved these files
df <- readRDS("output/03_analysis_data.rds")   # 28,556 rows from 03_summary_stats.R

# ---- 1. Numeric IVs to check: column name = label for plots ----
num_vars <- c(
  "Ordered Quantity"   = "Ordered Quantity",
  "Illustrative Price" = "Unit Price (USD)",
  "line_value"         = "Line Value (USD)",
  "lines_per_order"    = "Lines per Order",
  "planned_lead"       = "Planned Lead Time (days)",
  "request_gap"        = "Promise vs. Request (days)",
  "USAID Approval"     = "USAID Approval Time (days)",
  "Process PO/DO"      = "PO Processing Time (days)",
  "entry_to_po"        = "Entry to PO (days)",
  "days_left_at_po"    = "Days Left at PO (days)",
  "slack"              = "Supplier Slack (days)"
)
X <- as.data.frame(lapply(names(num_vars), function(v) as.numeric(df[[v]])))
names(X) <- names(num_vars)

# Helper: draw one box plot per variable on a 3 x 4 grid and save as PNG
draw_boxplots <- function(data, file, main_title, log_vars = character(0)) {
  png(file, width = 1600, height = 1100, res = 110)
  par(mfrow = c(3, 4), mar = c(3, 4, 3, 1), oma = c(0, 0, 2, 0))
  for (v in names(num_vars)) {
    x <- data[[v]]
    lab <- num_vars[[v]]
    if (v %in% log_vars) { x <- log10(x + 1); lab <- paste0("log10(", lab, " + 1)") }
    boxplot(x, horizontal = FALSE, col = "lightsteelblue", outcol = "firebrick",
            outpch = 16, outcex = 0.5, main = lab, cex.main = 0.9)
  }
  mtext(main_title, outer = TRUE, cex = 1.1, font = 2)
  dev.off()
}

# ---- 2. Box plots on the raw scale ----
dir.create("output", showWarnings = FALSE)
draw_boxplots(X, "output/04_boxplots_raw.png", "Box plots of numeric IVs (raw values, n = 28,556)")

# ---- 3. Tukey box-plot outliers: below Q1 - 1.5*IQR or above Q3 + 1.5*IQR ----
tukey <- function(x) {
  x  <- x[!is.na(x)]
  q  <- quantile(x, c(0.25, 0.5, 0.75), names = FALSE)
  iq <- q[3] - q[1]
  lo <- q[1] - 1.5 * iq; hi <- q[3] + 1.5 * iq
  c(N = length(x), Min = min(x), Q1 = q[1], Median = q[2], Q3 = q[3], Max = max(x),
    Lower_fence = lo, Upper_fence = hi,
    Out_low = sum(x < lo), Out_high = sum(x > hi),
    Out_pct = round(100 * mean(x < lo | x > hi), 1))
}
outlier_tbl <- data.frame(Variable = unname(num_vars), t(sapply(X, tukey)),
                          row.names = NULL, check.names = FALSE)
outlier_tbl

# ---- 4. Rule-based check: values that cannot be real ----
yr <- function(d) as.numeric(format(d, "%Y"))
fake_add  <- yr(df$`Agreed Delivery Date`) > 2030                                   # placeholder dates (e.g., 2099)
fake_cga  <- yr(df$`Committed Goods Available Date`) > 2030 & !is.na(df$`Committed Goods Available Date`)
fake_req  <- yr(df$`Requested Delivery Date`) > 2030 & !is.na(df$`Requested Delivery Date`)
neg_lead  <- X$planned_lead < 0                                                     # promised date before order entry
neg_usaid <- X$`USAID Approval` < 0 & !is.na(X$`USAID Approval`)                   # USAID approved before country approval
zero_qty  <- X$`Ordered Quantity` == 0                                              # nothing ordered

rule_tbl <- data.frame(
  Rule = c("Promised (agreed) delivery date after 2030",
           "Supplier committed goods date after 2030",
           "Requested delivery date after 2030",
           "Planned lead time < 0 (promised date before order entry)",
           "USAID approval time < 0",
           "Ordered quantity = 0"),
  Affects = c("Planned Lead, Promise vs. Request, Days Left at PO, Supplier Slack",
              "Supplier Slack",
              "Promise vs. Request",
              "Planned Lead Time",
              "USAID Approval Time",
              "Ordered Quantity, Line Value"),
  Rows = c(sum(fake_add), sum(fake_cga), sum(fake_req), sum(neg_lead), sum(neg_usaid), sum(zero_qty))
)
rule_tbl

# ---- 5. Proposal: set error values to NA, then compare ----
Y <- X
Y$planned_lead[fake_add | neg_lead]          <- NA
Y$request_gap[fake_add | fake_req]           <- NA
Y$days_left_at_po[fake_add]                  <- NA
Y$slack[fake_add | fake_cga]                 <- NA
Y$`USAID Approval`[neg_usaid]                <- NA
Y$`Ordered Quantity`[zero_qty]               <- NA
Y$line_value[zero_qty]                       <- NA

# Skewed size variables are shown on a log scale (real large orders, not errors)
size_vars <- c("Ordered Quantity", "Illustrative Price", "line_value", "lines_per_order")
draw_boxplots(Y, "output/04_boxplots_after_rules.png",
              "Box plots after removing impossible values (size variables on log10 scale)",
              log_vars = size_vars)

# Before / after summary for each variable
ba <- function(x) c(N = sum(!is.na(x)), Mean = mean(x, na.rm = TRUE), Std.Dev = sd(x, na.rm = TRUE),
                    Min = min(x, na.rm = TRUE), Median = median(x, na.rm = TRUE), Max = max(x, na.rm = TRUE))
before_after <- data.frame(
  Variable = rep(unname(num_vars), each = 2),
  Version  = rep(c("Before", "After rules"), times = length(num_vars)),
  do.call(rbind, lapply(names(num_vars), function(v) rbind(ba(X[[v]]), ba(Y[[v]])))),
  check.names = FALSE)
before_after[, -(1:2)] <- round(before_after[, -(1:2)], 1)
before_after

# Tukey outliers again, after the rules (size variables on log scale)
Y_log <- Y
for (v in size_vars) Y_log[[v]] <- log10(Y_log[[v]] + 1)
outlier_after <- data.frame(Variable = unname(num_vars),
                            Scale = ifelse(names(num_vars) %in% size_vars, "log10(x+1)", "raw"),
                            t(sapply(Y_log, tukey)), row.names = NULL, check.names = FALSE)
outlier_after

# ---- 6. Save ----
write.csv(outlier_tbl,   "output/04_tukey_outliers_raw.csv",   row.names = FALSE)
write.csv(rule_tbl,      "output/04_rule_errors.csv",          row.names = FALSE)
write.csv(before_after,  "output/04_before_after.csv",         row.names = FALSE)
write.csv(outlier_after, "output/04_tukey_outliers_after.csv", row.names = FALSE)
