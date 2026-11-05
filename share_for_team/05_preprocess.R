# ============================================================
# BUAN6356 Group Project - Step E: Pre-processing
# Decisions and reasons: README.md, section 6
#   Decision 1: remove rows with impossible values (expected 98 rows)
#   Decision 2: add log10(x + 1) versions of 4 size variables (for Logistic Regression)
#   Decision 3: keep real but extreme values (no trimming / capping)
#   Decision 4: remove rows with a missing numeric predictor (expected 508 rows)
# Output: final modeling data (expected 27,950 rows) + final summary statistics table
# Base R only (no packages needed)
# ============================================================

setwd("C:/BIZANwR")   # <- CHANGE to the folder where you saved these files
df <- readRDS("output/03_analysis_data.rds")   # 28,556 rows from 03_summary_stats.R
n_start <- nrow(df)

# ---- Decision 1. Impossible values ----
yr <- function(d) as.numeric(format(d, "%Y"))
req_after_entry <- as.numeric(df$`Requested Delivery Date` - df$`Order Entry Date`)

rules <- data.frame(
  add_after_2030 = yr(df$`Agreed Delivery Date`) > 2030,
  cga_after_2030 = yr(df$`Committed Goods Available Date`) > 2030 & !is.na(df$`Committed Goods Available Date`),
  req_after_2030 = yr(df$`Requested Delivery Date`) > 2030 & !is.na(df$`Requested Delivery Date`),
  req_over_5yrs  = req_after_entry > 1826 & !is.na(req_after_entry),        # more than 5 years after entry
  add_before_entry = df$planned_lead < 0,
  usaid_negative = df$`USAID Approval` < 0 & !is.na(df$`USAID Approval`),
  qty_zero       = df$`Ordered Quantity` == 0
)
rule_tbl <- data.frame(
  Rule = c("Promised (agreed) delivery date after 2030",
           "Supplier committed goods date after 2030",
           "Requested delivery date after 2030",
           "Requested delivery date more than 5 years after order entry",
           "Promised date earlier than order entry",
           "USAID approval time < 0",
           "Ordered quantity = 0"),
  Rows = colSums(rules), row.names = NULL)
rule_tbl                                   # rule counts add to 99 (one row is caught twice)
is_error <- rowSums(rules) > 0
sum(is_error)                              # expected 98
df <- df[!is_error, ]
n_after_rules <- nrow(df)

# ---- Decision 4. Rows with a missing numeric predictor ----
num_cols <- c("Ordered Quantity", "Illustrative Price", "line_value", "lines_per_order",
              "planned_lead", "request_gap", "USAID Approval", "Process PO/DO",
              "entry_to_po", "days_left_at_po", "slack")
colSums(is.na(df[, num_cols]))             # where the blanks are
has_na <- !complete.cases(df[, num_cols])
sum(has_na)                                # expected 508
# Check: outcome rate of removed vs kept rows should be similar (about 11.0% vs 11.4%)
c(removed = mean(df$dv_not_on_time[has_na]), kept = mean(df$dv_not_on_time[!has_na]))
df <- df[!has_na, ]

step_log <- data.frame(
  Step      = c("Analysis sample (from 03)", "Decision 1: impossible values", "Decision 4: missing numeric predictor"),
  Removed   = c(NA, n_start - n_after_rules, n_after_rules - nrow(df)),
  Remaining = c(n_start, n_after_rules, nrow(df)))
step_log                                   # expected final: 27,950

# ---- Build the modeling data with short, clean column names ----
# Factor levels are ordered from most to least common, so the most common
# group is the reference level in Logistic Regression.
as_factor_by_freq <- function(x) factor(x, levels = names(sort(table(x), decreasing = TRUE)))

model_data <- data.frame(
  # IDs kept for splitting the data later (not predictors)
  order_number        = df$`Order Number`,
  order_entry_date    = df$`Order Entry Date`,
  # Dependent variables
  dv_not_on_time      = df$dv_not_on_time,      # DV A (main)
  dv_late_only        = df$dv_late_only,        # DV B (robustness)
  # Numeric predictors (original values; Decision 3 = keep extreme values)
  ordered_qty         = as.numeric(df$`Ordered Quantity`),
  unit_price          = as.numeric(df$`Illustrative Price`),
  line_value          = df$line_value,
  lines_per_order     = df$lines_per_order,
  planned_lead        = df$planned_lead,
  request_gap         = df$request_gap,
  usaid_approval_days = as.numeric(df$`USAID Approval`),
  po_processing_days  = as.numeric(df$`Process PO/DO`),
  entry_to_po         = df$entry_to_po,
  days_left_at_po     = df$days_left_at_po,
  slack               = df$slack,
  # Categorical predictors
  order_type          = as_factor_by_freq(df$cat_order_type),
  tlp                 = as_factor_by_freq(df$cat_tlp),
  transport           = as_factor_by_freq(df$cat_transport),
  task_order          = as_factor_by_freq(df$cat_task_order),
  product             = as_factor_by_freq(df$cat_product),
  country             = as_factor_by_freq(df$cat_country),
  framework           = as_factor_by_freq(df$cat_framework),
  funding             = as_factor_by_freq(df$cat_funding),
  vendor_inco         = as_factor_by_freq(df$cat_vendor_inco),
  dest_inco           = as_factor_by_freq(df$cat_dest_inco)
)

# ---- Decision 2. log10(x + 1) versions of the size variables ----
# Used by Logistic Regression. Decision Tree uses the original values.
model_data$log_ordered_qty     <- log10(model_data$ordered_qty + 1)
model_data$log_unit_price      <- log10(model_data$unit_price + 1)
model_data$log_line_value      <- log10(model_data$line_value + 1)
model_data$log_lines_per_order <- log10(model_data$lines_per_order + 1)

str(model_data)
c(rows = nrow(model_data), any_NA = sum(!complete.cases(model_data)))   # expected 27950, 0
c(dv_A = mean(model_data$dv_not_on_time), dv_B = mean(model_data$dv_late_only))  # about 0.114, 0.104

# ---- Final summary statistics table (guideline Table 1 format) ----
stat_row <- function(x) c(Mean = mean(x), Std.Dev = sd(x), Min = min(x), Max = max(x))

num_info <- list(
  c("dv_not_on_time",      "Not On Time (DV A)",         "DV",              "1 = delivered outside 14 days early to 7 days late vs. promised date"),
  c("dv_late_only",        "Late Only (DV B)",           "DV (robustness)", "1 = delivered more than 7 days late"),
  c("ordered_qty",         "Ordered Quantity",           "IV", "Number of units ordered (log10 used in Logistic Regression)"),
  c("unit_price",          "Unit Price (USD, assumed)",  "IV", "Estimated price per ordered unit (log10 used in Logistic Regression)"),
  c("line_value",          "Line Value (USD)",           "IV", "Ordered quantity x unit price (log10 used in Logistic Regression)"),
  c("lines_per_order",     "Lines per Order",            "IV", "Number of lines in the same order (log10 used in Logistic Regression)"),
  c("planned_lead",        "Planned Lead Time (days)",   "IV", "Promised date - order entry date"),
  c("request_gap",         "Promise vs. Request (days)", "IV", "Promised date - date the country asked for"),
  c("usaid_approval_days", "USAID Approval Time (days)", "IV", "Days from country approval to USAID approval"),
  c("po_processing_days",  "PO Processing Time (days)",  "IV", "Days from USAID approval to purchase order release"),
  c("entry_to_po",         "Entry to PO (days)",         "IV", "Days from order entry to purchase order release"),
  c("days_left_at_po",     "Days Left at PO (days)",     "IV", "Promised date - PO release date (negative = already past)"),
  c("slack",               "Supplier Slack (days)",      "IV", "Promised date - date supplier promised goods ready")
)
num_tbl <- do.call(rbind, lapply(num_info, function(v)
  data.frame(Variable = v[2], Role = v[3], Type = "Numeric", Definition = v[4],
             t(stat_row(model_data[[v[1]]])), check.names = FALSE)))

cat_info <- list(
  c("order_type",  "Order Type",           "Purchase order or distribution order"),
  c("tlp",         "TLP Indicator",        "Logistics channel code (meaning not documented)"),
  c("transport",   "Transportation Mode",  "Planned transport mode (assumed)"),
  c("task_order",  "Task Order",           "Program area (condom-adjusted)"),
  c("product",     "Product Category",     "Product type (small groups = Other)"),
  c("country",     "Country",              "Recipient country (small countries = Other)"),
  c("framework",   "Framework Contract",   "Bought under a long-term supplier contract"),
  c("funding",     "Funding Source",       "Type of funding"),
  c("vendor_inco", "Vendor Incoterm",      "Shipping terms with the supplier"),
  c("dest_inco",   "Destination Incoterm", "Shipping terms for delivery to the country")
)
cat_tbl <- do.call(rbind, lapply(cat_info, function(v) {
  x <- model_data[[v[1]]]
  do.call(rbind, lapply(levels(x), function(l)
    data.frame(Variable = paste0(v[2], ": ", l), Role = "IV", Type = "Dummy (0/1)",
               Definition = v[3], t(stat_row(as.numeric(x == l))), check.names = FALSE)))
}))

final_tbl <- rbind(num_tbl, cat_tbl)
final_tbl[, c("Mean", "Std.Dev", "Min", "Max")] <- round(final_tbl[, c("Mean", "Std.Dev", "Min", "Max")], 3)
print(final_tbl[, c("Variable", "Role", "Mean", "Std.Dev", "Min", "Max")], row.names = FALSE)

# ---- Save ----
dir.create("output", showWarnings = FALSE)
write.csv(rule_tbl,  "output/05_rule_errors.csv",          row.names = FALSE)
write.csv(step_log,  "output/05_preprocess_log.csv",       row.names = FALSE)
write.csv(final_tbl, "output/05_summary_stats_final.csv",  row.names = FALSE)
saveRDS(model_data,  "output/05_model_data.rds")   # use this file for Decision Tree and Logistic Regression
