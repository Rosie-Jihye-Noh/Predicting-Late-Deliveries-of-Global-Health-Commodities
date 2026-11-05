# ============================================================
# BUAN6356 Group Project - Step C: Analysis sample + summary statistics
#   1) Apply the row exclusions decided in Step2_Variable_Selection.md
#   2) Build the dependent variables (DV A main, DV B robustness)
#   3) Build the 21 candidate independent variables (14 original + 7 new)
#   4) Make the summary statistics table (Mean / SD / Min / Max)
# Base R only (no packages needed)
# ============================================================

setwd("C:/BIZANwR")   # <- CHANGE to the folder where you saved these files

# Re-load data only if it is not already in memory
if (!exists("usaid")) {
  usaid <- read.csv("USAID_GHSC-PSM_Health_Commodity_Delivery_Dataset.csv",
                    check.names = FALSE, stringsAsFactors = FALSE,
                    na.strings = c("", "NA"), fileEncoding = "UTF-8")
}
raw <- usaid   # keep the original untouched

# ---- 1. Convert date text to Date ----
# Dates look like "Friday, July 7, 2017". Weekday and month names are English,
# so switch the time locale to "C" (English) before parsing.
Sys.setlocale("LC_TIME", "C")
parse_date <- function(x) as.Date(x, format = "%A, %B %d, %Y")

date_cols <- c("Order Entry Date", "Requested Delivery Date", "Agreed Delivery Date",
               "PO Released For Fulfillment Date", "Committed Goods Available Date",
               "Latest Actual Delivery Date")
for (col in date_cols) raw[[col]] <- parse_date(usaid[[col]])

# Check: every non-missing text date should become a real date (expect 0 failures)
date_check <- data.frame(
  Variable      = date_cols,
  Text_present  = sapply(date_cols, function(c) sum(!is.na(usaid[[c]]))),
  Parse_failed  = sapply(date_cols, function(c) sum(!is.na(usaid[[c]]) & is.na(raw[[c]]))),
  row.names = NULL)
date_check

# ---- 2. Lines per order (count on the full raw data, before any row is dropped) ----
raw$lines_per_order <- as.numeric(ave(raw$ROPOLine, raw$`Order Number`, FUN = length))

# ---- 3. Row exclusions (same order as the decision document) ----
steps <- list(
  "OTD missing"                     = !is.na(raw$`On Time (OTD)`),
  "Exclusion flag = Y"              = is.na(raw$`OTD OTIF Exclusion Flag`),
  "Replenishment order"             = raw$`Order Type` != "Replenishment Order",
  "PO date after actual delivery"   = !(raw$`PO Released For Fulfillment Date` >
                                          raw$`Latest Actual Delivery Date` &
                                        !is.na(raw$`PO Released For Fulfillment Date`) &
                                        !is.na(raw$`Latest Actual Delivery Date`)),
  "Entered before 2017-10-01"       = raw$`Order Entry Date` >= as.Date("2017-10-01")
)

keep <- rep(TRUE, nrow(raw))
exclusion_log <- data.frame(Step = "Original data", Removed = NA, Remaining = nrow(raw))
for (s in names(steps)) {
  before <- sum(keep)
  keep   <- keep & steps[[s]]
  exclusion_log <- rbind(exclusion_log,
                         data.frame(Step = s, Removed = before - sum(keep), Remaining = sum(keep)))
}
exclusion_log   # expected final: 28,556 rows

df <- raw[keep, ]

# ---- 4. Dependent variables ----
# DV A (main): 1 = outside the official -14/+7 day window (late OR too early)
df$dv_not_on_time <- as.numeric(df$`On Time (OTD)` == "N")
# DV B (robustness): 1 = more than 7 days late only
df$dv_late_only   <- as.numeric(df$`Line Delivery Status` == "Delivered - Late")
mean(df$dv_not_on_time)   # expected about 0.114
mean(df$dv_late_only)     # expected about 0.104

# ---- 5. New (derived) numeric variables, in days ----
days <- function(a, b) as.numeric(a - b)
df$line_value      <- df$`Ordered Quantity` * df$`Illustrative Price`
df$planned_lead    <- days(df$`Agreed Delivery Date`, df$`Order Entry Date`)
df$request_gap     <- days(df$`Agreed Delivery Date`, df$`Requested Delivery Date`)
df$days_left_at_po <- days(df$`Agreed Delivery Date`, df$`PO Released For Fulfillment Date`)
df$slack           <- days(df$`Agreed Delivery Date`, df$`Committed Goods Available Date`)
df$entry_to_po     <- days(df$`PO Released For Fulfillment Date`, df$`Order Entry Date`)

# ---- 6. Categorical variables: clean and group ----
# Keep levels with at least min_n rows; the rest become "Other"
lump <- function(x, min_n = 500) {
  tab  <- table(x)
  keep <- names(tab)[tab >= min_n]
  ifelse(x %in% keep, x, "Other")
}
na_to <- function(x, label = "Unknown") ifelse(is.na(x), label, x)

df$cat_order_type   <- df$`Order Type`
df$cat_tlp          <- df$`TLP Indicator`
df$cat_transport    <- df$`Transportation Mode`
df$cat_task_order   <- df$`Condom Adjusted Task Order`
# The data already has a level called "Others"; merge it into our "Other" group
prod <- df$`Product Category`
prod[prod == "Others"] <- "Other"
df$cat_product      <- lump(prod)
df$cat_country      <- lump(df$Country)
df$cat_framework    <- na_to(df$`Framework Contract`)

fund <- df$`D365 Funding Source`
fund[fund %in% c("MissionCommodity Funding", "COP Mission")] <- "Mission Commodity Funding"  # assumed spelling variants
df$cat_funding      <- na_to(fund)

vin <- toupper(substr(trimws(df$`Vendor Incoterm`), 1, 3))   # keep the 3-letter code
vin <- ifelse(is.na(vin), NA, ifelse(vin %in% c("FCA", "DDP", "DAP", "CIP"), vin, "Other"))
df$cat_vendor_inco  <- na_to(vin)

din <- df$`Destination Incoterm`
din <- ifelse(is.na(din), NA, ifelse(din %in% c("DAP", "DDP"), din, "Other"))
df$cat_dest_inco    <- na_to(din)

# ---- 7. Summary statistics table ----
stat_row <- function(x) {
  x <- as.numeric(x)
  c(N = sum(!is.na(x)), Missing = sum(is.na(x)),
    Mean = mean(x, na.rm = TRUE), Std.Dev = sd(x, na.rm = TRUE),
    Min = min(x, na.rm = TRUE), Max = max(x, na.rm = TRUE))
}

# (a) DV + numeric IVs: name in data, label, role, definition
num_vars <- list(
  c("dv_not_on_time",   "Not On Time (DV A)",            "DV",  "1 = delivered outside 14 days early to 7 days late vs. promised date"),
  c("dv_late_only",     "Late Only (DV B)",              "DV (robustness)", "1 = delivered more than 7 days late"),
  c("Ordered Quantity", "Ordered Quantity",              "IV",  "Number of units ordered"),
  c("Illustrative Price","Unit Price (USD, assumed)",    "IV",  "Estimated price per ordered unit"),
  c("line_value",       "Line Value (USD)",              "IV (new)", "Ordered quantity x unit price"),
  c("lines_per_order",  "Lines per Order",               "IV (new)", "Number of lines in the same order"),
  c("planned_lead",     "Planned Lead Time (days)",      "IV (new)", "Promised date - order entry date"),
  c("request_gap",      "Promise vs. Request (days)",    "IV (new)", "Promised date - date the country asked for"),
  c("USAID Approval",   "USAID Approval Time (days)",    "IV",  "Days from country approval to USAID approval"),
  c("Process PO/DO",    "PO Processing Time (days)",     "IV",  "Days from USAID approval to purchase order release"),
  c("entry_to_po",      "Entry to PO (days)",            "IV (new)", "Days from order entry to purchase order release"),
  c("days_left_at_po",  "Days Left at PO (days)",        "IV (new)", "Promised date - PO release date (negative = already past)"),
  c("slack",            "Supplier Slack (days)",         "IV (new)", "Promised date - date supplier promised goods ready")
)
num_tbl <- do.call(rbind, lapply(num_vars, function(v)
  data.frame(Variable = v[2], Role = v[3], Type = "Numeric", Definition = v[4],
             t(stat_row(df[[v[1]]])), check.names = FALSE)))

# (b) Categorical IVs as 0/1 dummies (mean = share of rows in that group)
cat_vars <- list(
  c("cat_order_type",  "Order Type",            "Purchase order or distribution order"),
  c("cat_tlp",         "TLP Indicator",         "Logistics channel code (meaning not documented)"),
  c("cat_transport",   "Transportation Mode",   "Planned transport mode (assumed)"),
  c("cat_task_order",  "Task Order",            "Program area (condom-adjusted)"),
  c("cat_product",     "Product Category",      "Product type (groups under 500 rows = Other)"),
  c("cat_country",     "Country",               "Recipient country (countries under 500 rows = Other)"),
  c("cat_framework",   "Framework Contract",    "Bought under a long-term supplier contract"),
  c("cat_funding",     "Funding Source",        "Type of funding"),
  c("cat_vendor_inco", "Vendor Incoterm",       "Shipping terms with the supplier"),
  c("cat_dest_inco",   "Destination Incoterm",  "Shipping terms for delivery to the country")
)
cat_tbl <- do.call(rbind, lapply(cat_vars, function(v) {
  x    <- df[[v[1]]]
  lvls <- names(sort(table(x), decreasing = TRUE))
  do.call(rbind, lapply(lvls, function(l)
    data.frame(Variable = paste0(v[2], ": ", l), Role = "IV", Type = "Dummy (0/1)",
               Definition = v[3], t(stat_row(as.numeric(x == l))), check.names = FALSE)))
}))

summary_tbl <- rbind(num_tbl, cat_tbl)
summary_tbl[, c("Mean", "Std.Dev", "Min", "Max")] <-
  round(summary_tbl[, c("Mean", "Std.Dev", "Min", "Max")], 3)
print(summary_tbl[, c("Variable", "Role", "N", "Missing", "Mean", "Std.Dev", "Min", "Max")],
      row.names = FALSE)

# ---- 8. Save ----
dir.create("output", showWarnings = FALSE)
write.csv(exclusion_log, "output/03_exclusion_log.csv", row.names = FALSE)
write.csv(summary_tbl,   "output/03_summary_stats.csv", row.names = FALSE)
saveRDS(df,              "output/03_analysis_data.rds")   # analysis sample for the next steps
capture.output(date_check, exclusion_log,
               mean(df$dv_not_on_time), mean(df$dv_late_only),
               file = "output/03_checks.txt")
