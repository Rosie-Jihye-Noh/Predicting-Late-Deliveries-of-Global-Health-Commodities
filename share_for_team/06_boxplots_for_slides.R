# ============================================================
# BUAN6356 Group Project - Step F: Box plots for the slides
#   Before: analysis sample before pre-processing (output/03_analysis_data.rds, 28,556 rows)
#   After : final modeling data (output/05_model_data.rds, 27,950 rows),
#           size variables on a log10 scale
# Also prints the numbers quoted on the slides.
# Base R only (no packages needed)
# ============================================================

setwd("C:/BIZANwR")   # <- CHANGE to the folder where you saved these files
before <- readRDS("output/03_analysis_data.rds")
after  <- readRDS("output/05_model_data.rds")

# Same 11 numeric predictors in both files (names differ between the two files)
vars <- data.frame(
  label  = c("Ordered Quantity", "Unit Price (USD)", "Line Value (USD)", "Lines per Order",
             "Planned Lead Time (days)", "Promise vs. Request (days)", "USAID Approval Time (days)",
             "PO Processing Time (days)", "Entry to PO (days)", "Days Left at PO (days)",
             "Supplier Slack (days)"),
  before = c("Ordered Quantity", "Illustrative Price", "line_value", "lines_per_order",
             "planned_lead", "request_gap", "USAID Approval", "Process PO/DO",
             "entry_to_po", "days_left_at_po", "slack"),
  after  = c("ordered_qty", "unit_price", "line_value", "lines_per_order",
             "planned_lead", "request_gap", "usaid_approval_days", "po_processing_days",
             "entry_to_po", "days_left_at_po", "slack"),
  size   = c(TRUE, TRUE, TRUE, TRUE, rep(FALSE, 7)),
  stringsAsFactors = FALSE
)

# Draw 11 box plots on a 3 x 4 grid, sized for a 16:9 slide
draw <- function(data, cols, file, log_size = FALSE) {
  png(file, width = 2400, height = 1350, res = 150)
  par(mfrow = c(3, 4), mar = c(2.5, 6, 3, 1), cex.axis = 1.1)
  for (i in seq_len(nrow(vars))) {
    x   <- as.numeric(data[[cols[i]]])
    lab <- vars$label[i]
    if (log_size && vars$size[i]) { x <- log10(x + 1); lab <- paste0("log10(", vars$label[i], " + 1)") }
    boxplot(x, col = "#C9D6E8", border = "#14213D", outcol = "#B8621B", outpch = 16,
            outcex = 0.6, main = lab, cex.main = 1.25, las = 1)
  }
  dev.off()
}

dir.create("output", showWarnings = FALSE)
draw(before, vars$before, "output/06_boxplots_before.png")
draw(after,  vars$after,  "output/06_boxplots_after.png", log_size = TRUE)

# ---- Numbers quoted on the slides (final data, 27,950 rows) ----
tukey_out <- function(x) {
  q <- quantile(x, c(0.25, 0.75), na.rm = TRUE); iq <- q[2] - q[1]
  x < q[1] - 1.5 * iq | x > q[2] + 1.5 * iq
}
# Share of box-plot dots after pre-processing (size variables on log scale)
out_pct <- sapply(seq_len(nrow(vars)), function(i) {
  x <- as.numeric(after[[vars$after[i]]])
  if (vars$size[i]) x <- log10(x + 1)
  round(100 * mean(tukey_out(x)), 1)
})
names(out_pct) <- vars$label
out_pct

# Not On Time rate for lines shown as dots vs. the rest (long waits are a signal)
signal <- function(col) {
  o <- tukey_out(after[[col]])
  c(dots_n = sum(o), dots_rate = round(100 * mean(after$dv_not_on_time[o]), 1),
    rest_rate = round(100 * mean(after$dv_not_on_time[!o]), 1),
    fence = round(unname(quantile(after[[col]], 0.75) + 1.5 * IQR(after[[col]])), 1))
}
rbind(po_processing = signal("po_processing_days"), entry_to_po = signal("entry_to_po"),
      usaid_approval = signal("usaid_approval_days"))

# Spread before vs. after for the date-based variables
sapply(c("planned_lead", "request_gap", "days_left_at_po", "slack"), function(v)
  c(sd_before = round(sd(before[[v]], na.rm = TRUE)), sd_after = round(sd(after[[v]])),
    max_before = max(before[[v]], na.rm = TRUE), max_after = max(after[[v]])))
