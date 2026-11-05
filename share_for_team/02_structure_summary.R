# ============================================================
# BUAN6356 Group Project - Step B: Structure summary of all 104 variables
# (type, missing values, number of unique values, example) + definitions
# ============================================================

setwd("C:/BIZANwR")   # <- CHANGE to the folder where you saved these files

# Re-load data only if it is not already in memory
if (!exists("usaid")) {
  usaid <- read.csv("USAID_GHSC-PSM_Health_Commodity_Delivery_Dataset.csv",
                    check.names = FALSE, stringsAsFactors = FALSE,
                    na.strings = c("", "NA"), fileEncoding = "UTF-8")
}

# ---- 1. One row per variable ----
structure_tbl <- data.frame(
  No        = seq_along(usaid),
  Variable  = names(usaid),
  R_Type    = sapply(usaid, function(x) class(x)[1]),             # character / integer / numeric
  N_Missing = sapply(usaid, function(x) sum(is.na(x))),           # number of NA values
  N_Unique  = sapply(usaid, function(x) length(unique(na.omit(x)))),  # distinct non-missing values
  Example   = sapply(usaid, function(x) as.character(na.omit(x))[1]), # first non-missing value
  row.names = NULL
)
structure_tbl$Pct_Missing <- round(100 * structure_tbl$N_Missing / nrow(usaid), 1)

# ---- 2. Attach definitions from the data dictionary ----
dict <- read.csv("data_dictionary.csv", check.names = FALSE,
                 stringsAsFactors = FALSE, fileEncoding = "UTF-8")
structure_tbl <- merge(structure_tbl, dict, by = "Variable", all.x = TRUE, sort = FALSE)

# Date-derived columns (Year / Year Month / Fiscal Year / Fiscal Quarter Year) are duplicates
derived <- grepl("( Year| Year Month| Fiscal Year| Fiscal Quarter Year)$", structure_tbl$Variable)
structure_tbl$Group[derived]      <- "Derived_Date"
structure_tbl$Definition[derived] <- "Calendar / fiscal part of a date column (duplicate)"
structure_tbl$Note[derived]       <- "Drop"

structure_tbl <- structure_tbl[order(structure_tbl$No), ]   # back to original column order

# ---- 3. Quick overview ----
table(structure_tbl$R_Type)    # how many character / integer / numeric columns
table(structure_tbl$Group)     # how many columns in each group
# Columns with the most missing values
head(structure_tbl[order(-structure_tbl$N_Missing), c("Variable", "N_Missing", "Pct_Missing")], 15)
# Columns with only one value (no information)
structure_tbl$Variable[structure_tbl$N_Unique <= 1]

# ---- 4. Save ----
dir.create("output", showWarnings = FALSE)
write.csv(structure_tbl, "output/02_structure_summary.csv", row.names = FALSE)
capture.output(table(structure_tbl$R_Type),
               table(structure_tbl$Group),
               head(structure_tbl[order(-structure_tbl$N_Missing),
                                  c("Variable", "N_Missing", "Pct_Missing")], 15),
               structure_tbl$Variable[structure_tbl$N_Unique <= 1],
               file = "output/02_overview.txt")
