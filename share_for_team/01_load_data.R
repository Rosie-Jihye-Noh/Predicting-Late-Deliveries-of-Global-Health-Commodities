# ============================================================
# BUAN6356 Group Project - Step A: Load data & check structure
# ============================================================

# ---- 1. Set working directory (folder that holds the CSV) ----
# Windows paths in R use forward slashes "/" (or double backslashes "\\")
setwd("C:/BIZANwR")   # <- CHANGE to the folder where you saved these files
getwd()          # should print "C:/BIZANwR"
list.files()     # the USAID csv file should appear in this list

# ---- 2. Load the CSV ----
usaid <- read.csv("USAID_GHSC-PSM_Health_Commodity_Delivery_Dataset.csv",
                  check.names      = FALSE,          # keep original column names (e.g., "On Time (OTD)")
                  stringsAsFactors = FALSE,          # keep text as character for now
                  na.strings       = c("", "NA"),    # treat empty cells as missing (NA)
                  fileEncoding     = "UTF-8")        # file is UTF-8 (e.g., "Cote d'Ivoire" with accent)

# ---- 3. First look ----
dim(usaid)        # expected: 39681 rows, 104 columns
names(usaid)      # all 104 column names

# str() shows only the first 99 columns by default ("[list output truncated]").
# list.len = ncol(usaid) forces it to show all 104 columns.
str(usaid, list.len = ncol(usaid))

# ---- 4. Save outputs to text files (easier to share than copying the console) ----
dir.create("output", showWarnings = FALSE)   # create an "output" folder if it does not exist
capture.output(dim(usaid), names(usaid),
               file = "output/01_dim_names.txt")
capture.output(str(usaid, list.len = ncol(usaid)),
               file = "output/01_str.txt")
