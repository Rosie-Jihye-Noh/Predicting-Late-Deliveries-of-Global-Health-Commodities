# Group D – Data Exploration & Pre-processing package

Prepared by Jihye (Part 1: variable statistics) and reviewed by Indra (Part 1: outliers and pre-processing). Indra re-ran scripts 03–05 and got the same row counts.
Date: 2026-11-04, updated 2026-11-12 · Data: USAID GHSC-PSM Health Commodity Delivery Dataset

---

## 1. What is in this folder

| File | What it is |
|---|---|
| `USAID_GHSC-PSM_Health_Commodity_Delivery_Dataset.zip` | Original data, zipped because the CSV (42 MB) is too large for GitHub's browser upload. **Unzip it into this same folder first**; it contains `USAID_GHSC-PSM_Health_Commodity_Delivery_Dataset.csv` (39,681 rows × 104 columns). Source: data.usaid.gov dataset tikn-bfy4, Internet Archive snapshot of June 11, 2024 (link in the proposal). |
| `data_dictionary.csv` | For each of the 76 base columns: plain-English definition, timing ("when is it known?"), clarity note, and **Decision + Reason** (IV / Input or filter / DV source / Not used, and why) |
| `01_load_data.R` … `06_boxplots_for_slides.R` | R scripts. Run them in this order (base R only, no packages). |
| `output/` | Results of each script, so you can use them without re-running |
| `output/05_model_data.rds` | **The final modeling data. Use this for the Decision Tree and Logistic Regression.** |
| `output/05_summary_stats_final.csv` | Table 1 (mean, SD, min, max) on the final data |
| `output/06_boxplots_before.png`, `06_boxplots_after.png` | Box plots used in the slides |
| `docs/Project_Proposal_Final_short.md`, `docs/Project_Proposal_Final.md` | Proposal (short version for submission; long version with references) |
| `08_decision_tree.R` | Decision Tree: time split, growing and pruning the tree, tree plot (Aarushi; see section 7) |
| `output/08_tree_models.rds` | **The fitted trees. Vishnu: use `final_tree` for accuracy on the training and test data.** |
| `Part2_Decision_Tree.pptx` | Decision Tree slides (8 slides, with speaker notes), same design as Part 1 |

**What each script does**

| Script | Input → output | Purpose |
|---|---|---|
| 01 | CSV → `01_*.txt` | Load the data and print its structure |
| 02 | CSV + dictionary → `02_*` | One row per column: type, missing, unique values, definition |
| 03 | CSV → `03_analysis_data.rds` (28,556 rows) | Row exclusions, outcomes, new variables, first summary table |
| 04 | `03_…rds` → `04_*` | Outlier exploration (box plots, rules). Used to decide pre-processing. |
| 05 | `03_…rds` → `05_model_data.rds` (27,950 rows) | The actual pre-processing |
| 06 | `03_…rds`, `05_…rds` → `06_*.png` | Box plots for the slides |
| 08 | `05_…rds` → `08_*` | Decision Tree (needs the `rpart` and `rpart.plot` packages) |

---

## 2. Key decisions (all checked against the data)

**Outcome (DV)**
- **Main, DV A, `dv_not_on_time`:** 1 = delivered outside the program’s official window (more than 14 days early or more than 7 days late versus the agreed delivery date). Source: GHSC-PSM FY2018 Annual Report. The dataset’s OTD column follows this rule in 97.9% of rows. **11.4%** of final lines.
- **Robustness, DV B, `dv_late_only`:** 1 = more than 7 days late. **10.4%**. The difference is 263 lines that arrived too early.

**Prediction point:** purchase-order (PO) release. Every predictor must be known by then. Information recorded later (shipped quantity, actual dates, shipping-stage durations) is excluded because it would leak the answer.

**Rows: 39,681 → 27,950**

| Step | Removed | Left |
|---|---|---|
| No OTD result | 10 | 39,671 |
| Excluded by the program (exclusion flag) | 25 | 39,646 |
| Replenishment orders (to warehouses, not countries) | 1,678 | 37,968 |
| PO date after actual delivery (date error) | 2,962 | 35,006 |
| Orders entered before 2017-10-01 (start-up period; program restructured at FY2018 start) | 6,450 | 28,556 |
| Likely errors (7 rules, e.g., dates in 2099) | 98 | 28,458 |
| Missing numeric predictor | 508 | **27,950** |

**Columns: 104 → 29** (details on the slide "From 104 columns to 21 predictors")
- 28 duplicate date parts dropped → 76 base columns → 14 used as is, 7 used to build new variables or filter rows, 55 not used (27 of them are post-PO information).
- Column by column: see the `Decision` and `Reason` columns of `data_dictionary.csv`. The 55 "not used" are 52 marked `Not used` + 3 marked `DV source` (used only to build the outcome).
- Model data = 2 outcomes + 21 predictors (11 numeric, 10 categorical) + 4 log versions + 2 IDs.

**Pre-processing (Indra’s part; reasons and numbers in section 6)**
1. Remove 98 lines flagged as likely errors.
2. Add log10(x + 1) of 4 size variables for Logistic Regression only.
3. Keep plausible extreme values (no trimming).
4. Remove 508 lines with a missing numeric predictor so both models use the same rows.

---

## 3. How to reproduce

1. Put everything in one folder and **unzip `USAID_GHSC-PSM_Health_Commodity_Delivery_Dataset.zip` into that same folder**, so the CSV sits next to the R scripts. In each script, change the line `setwd("C:/BIZANwR")` to your folder.
2. Run 01 → 06 in order. Scripts 04–06 need the output of 03 (and 06 needs 05).
3. Check these numbers:
   - 03: final line of `output/03_exclusion_log.csv` = **28,556**
   - 05: `output/05_preprocess_log.csv` = **28,556 → 28,458 → 27,950**
   - DV A mean = **0.114**, DV B mean = **0.104**

---

## 4. For the modeling team (Decision Tree and Logistic Regression)

```r
m <- readRDS("output/05_model_data.rds")   # 27,950 rows × 29 columns, no missing values
```

| Columns | Use |
|---|---|
| `order_number`, `order_entry_date` | IDs. **Not predictors.** Use the date to split by time. |
| `dv_not_on_time` (main), `dv_late_only` (robustness) | Outcomes (0/1) |
| `ordered_qty`, `unit_price`, `line_value`, `lines_per_order` | Size variables (original values) |
| `log_ordered_qty`, `log_unit_price`, `log_line_value`, `log_lines_per_order` | log10(x + 1) of the above: **Logistic Regression only** |
| `planned_lead`, `request_gap`, `usaid_approval_days`, `po_processing_days`, `entry_to_po`, `days_left_at_po`, `slack` | Durations in days |
| `order_type`, `tlp`, `transport`, `task_order`, `product`, `country`, `framework`, `funding`, `vendor_inco`, `dest_inco` | Categorical (factors). The first level is the most common group, so it is the reference in Logistic Regression. Decision Tree uses them directly. |

**What the proposal commits us to**
- **Split by time, not at random:** train on earlier orders, test on later ones.
  - Example: train = `order_entry_date < "2022-01-01"` gives 23,346 train lines (11.6% Not On Time) and 4,604 test lines (10.3%). The exact cut-off is your choice.
  - All lines of an order share one entry date, so this split never splits an order.
- **If you resample** (e.g., oversampling), do it on the **training data only**. Keep the test data at its real share of late lines.
- **Report recall for Not On Time and the confusion matrix,** not just accuracy. Predicting "on time" for everything already gives about 89% accuracy.
- Run DV B (`dv_late_only`) as a robustness check.

**⚠️ Two overlaps to handle in Logistic Regression** (checked in the data; not a problem for the Decision Tree)
1. `entry_to_po` = `planned_lead` − `days_left_at_po` **exactly**, for every row. If you include all three, R drops one and gives it an NA coefficient. **Use only two of the three** (for example, drop `planned_lead`).
2. `log_line_value` is almost the sum of `log_ordered_qty` + `log_unit_price` (correlation 0.99). Including all three makes their coefficients unstable. **Use either line value or quantity + price**, not all three.

**Optional robustness ideas**
- Log versions of `usaid_approval_days` (median 1, max 233) and `po_processing_days`, which are also skewed
- Capping extreme values at the 99th percentile
- All periods, including orders before Oct 2017, with a "start-up period" dummy

---

## 5. Assumptions and open points (stated on the slides)

- When some fields are recorded is not documented: transport mode, funding source, the two incoterms, lines per order. We assume they are known by PO release.
- We assume the supplier’s committed goods-ready date is not updated after PO release. If it is, `slack` may leak; a model without `slack` is a useful check.
- What TLP stands for is not documented. The likely meanings of GSC/DCP (central vs. decentralized procurement) and Mission/CORE (country vs. central funds) are our best reading, not official definitions.
- The Decision Tree example in the course guideline uses a random split; we use a time split, as stated in the proposal.

**Slides (Part 1, 18 slides):** `Part1_Data_Exploration.pptx`, shared as a PowerPoint file. This is the final deck, including Indra’s edits and speaker notes for slides 14–18. The text is editable, and speaker notes are in each slide’s notes. Footnotes point to slides by title or by "next slides", not by page number, so merging decks will not break them.

---

## 6. Pre-processing: rules and evidence (reviewed by Indra)

Input: `output/03_analysis_data.rds` (28,556 lines). Applied in `05_preprocess.R`. All figures below are from the final data unless marked.

**Two kinds of outliers.** A box plot marks every value below Q1 − 1.5 × IQR or above Q3 + 1.5 × IQR as a dot, but it does not say whether the value is wrong. So we separate:
- **likely errors**, which break a logical rule and are removed (Decision 1);
- **plausible extremes**, which are rare but could be real and are kept (Decision 3).

An analogy: in a list of student heights, 250 cm is a typing error, while 195 cm is a tall student. A box plot marks both the same way.

### Decision 1 — Remove lines flagged as likely errors (98 lines, 0.34%)

| Rule | Lines | Reason for flagging |
|---|---|---|
| Promised (agreed) delivery date after 2030 | 35 | Data ends in 2023; 2099 looks like a placeholder |
| Supplier’s committed goods-ready date after 2030 | 10 | Same reason |
| Requested delivery date after 2030 | 1 | Same reason |
| Requested date more than 5 years after order entry | 3 | Includes the 2099 line above; the other 2 show 2028. The next largest gap is 932 days. |
| Promised date earlier than order entry | 9 | A delivery cannot be promised before the order exists |
| USAID approval before the country’s approval (negative days) | 39 | The steps happen in a fixed order |
| Ordered quantity = 0 | 2 | Nothing was ordered |

The rule counts add up to 99. One line breaks two rules, so 98 lines are removed (`output/05_rule_errors.csv`).

We remove the whole line, not just the bad value. The share is tiny, and if one date in a line is a placeholder, its other dates are hard to trust.

"Before" below is the 28,556-line data; "after" is the final 27,950 lines, after the missing-value step as well.

| Variable | Std. dev. before → after | Max before → after |
|---|---|---|
| Planned lead time (days) | 1,024 → 122 | 30,032 → 1,462 |
| Days left at PO (days) | 1,012 → 87 | 29,749 → 1,274 |
| Supplier slack (days) | 1,146 → 81 | 29,746 → 1,141 |

### Decision 2 — log10(x + 1) of the 4 size variables, for Logistic Regression only

The size variables are ordered quantity, unit price, line value and lines per order. Most orders are small, but a few are huge: quantity has a median of 280 and a max of 2,890,944.

On the original scale, 18.7% of quantities are box-plot dots (before cleaning). On the log scale, that drops to 0%, so this is a normal long tail, not an error.

- **Logistic Regression** uses the log, so that a few huge orders do not dominate the coefficients.
- **Decision Tree** uses the original values. A tree only asks "is the value above X?", and the log does not change the order of values. The original values are also easier to read.

The "+1" avoids log(0).

### Decision 3 — Keep plausible extremes (no trimming)

| Group | Lines | Not On Time |
|---|---|---|
| PO processing time above the box-plot fence (> 127.5 days) | 2,065 | **16.2%** |
| PO processing time at or below the fence | 25,885 | 11.0% |
| Entry to PO above the fence (> 338.5 days) | 644 | **16.0%** |
| Entry to PO at or below the fence | 27,306 | 11.2% |

Not On Time is more common for longer waits. This is an observed association in this sample, not a causal effect, but it is information the model may use.

We did not cap them. Capping at the 99th percentile would turn PO processing times of 253 to 775 days into 253, and the difference between a long wait and a very long wait would be lost. Capping is a possible robustness check.

### Decision 4 — Remove lines with a missing numeric predictor (508 lines, 1.8%)

| Missing in | Lines | Why |
|---|---|---|
| Promise vs. request | 420 | Requested date not recorded |
| USAID approval time | 77 | Not recorded |
| PO processing time | 33 | Not recorded |
| Supplier slack | 10 | Supplier date not recorded |
| Unit price, line value | 2 | Price not recorded |

Some lines are missing more than one value, so the total is 508 lines.

**Why remove them?** In R, `glm` silently drops lines with blanks, while `rpart` keeps them. Without removal, the two models would learn from different rows and could not be compared fairly.

**Why it is safe:** the removed lines are 11.0% Not On Time, versus 11.4% for the lines we keep.

Blank *categories* (e.g., framework contract) are not removed; they stay as an "Unknown" group.

### Limits

- The error rules are our judgment; the dataset does not document placeholder dates, so we call them "likely" errors.
- "Plausible" means not ruled out by a rule. We did not confirm each value.
- Decisions 1 and 4 remove 606 lines (2.1%), and the outcome rate stays at 11.4%.
- `04_boxplot_outliers.R` and its `04_*` outputs are the exploration that led to these rules: 6 rules, with bad values blanked rather than removed. Their figures can differ slightly from the final ones above.

---

## 7. Decision Tree (Aarushi)

Script: `08_decision_tree.R` (input `output/05_model_data.rds`). Packages: `rpart` (comes with R) and `rpart.plot` (`install.packages("rpart.plot")` once). Slides: `Part2_Decision_Tree.pptx` (8 slides, speaker notes in each slide).

### Split by time

| Set | Orders entered | Lines | Orders | Not On Time |
|---|---|---|---|---|
| Training | Oct 2, 2017 – Dec 30, 2021 | 23,346 (83.5%) | 10,467 | 2,697 (11.6%) |
| Test | Jan 4, 2022 – Aug 8, 2023 | 4,604 (16.5%) | 2,281 | 476 (10.3%) |

Cut-off `order_entry_date < "2022-01-01"`, as in section 4. No order is in both sets. **Ethan: please use the same cut-off** so the two models are compared on the same lines.

### How the tree was grown

| Setting | Value | Why |
|---|---|---|
| Predictors | All 21, original scale (no log versions) | A tree only asks "above or below X?", so logs change nothing |
| `parms = list(prior = c(0.5, 0.5))` | Equal weight for both classes | With the default, the tree makes **0 splits** and predicts "On Time" for every line, because Not On Time never becomes the majority in any node |
| `cp = 0.0005`, `minbucket = 50` | Grow a large tree (131 splits) first | It is pruned back in the next step; every leaf keeps at least 50 lines |
| `xval` = 10 folds **grouped by order** | All lines of an order in the same fold | Lines of one order are near-duplicates; random folds make the CV error look too good |
| Pruning | 1-SE rule → **56 splits, 57 leaves** | Lowest CV error is at 64 leaves (0.663); 57 leaves is within one standard error (0.673) |

### Results used on the slides

- **Variable importance (top 5, share of 100):** supplier slack 12.6, country 11.3, product category 9.0, planned lead time 8.3, days left at PO 8.1. Quantity, price and line value together: 4.1.
- **Plotted tree:** the top 9 splits (10 leaves) of the final tree. Pruning only removes the lowest splits, so these are the final tree's first splits. Boxes show the **actual** Not On Time share of training lines (with equal priors, the probabilities rpart prints are re-weighted, not real shares).
- **First split:** supplier slack < 71 days → 15.2% Not On Time vs. 7.4%. Then country, PO processing time, planned lead time and transport mode (`output/08_tree_leaves.csv`).
- **Robustness:** without `slack`, and with DV B (late only), the first split is days left at PO and country stays in the top 3 (`output/08_robustness.csv`).

### For Vishnu (accuracy on the training and test data)

```r
library(rpart)
m     <- readRDS("output/05_model_data.rds")
trees <- readRDS("output/08_tree_models.rds")    # final_tree, display_tree, cutoff, predictors, ...
train <- m[m$order_entry_date <  trees$cutoff, ]
test  <- m[m$order_entry_date >= trees$cutoff, ]
pred_test <- predict(trees$final_tree, test, type = "class")   # "On Time" / "Not On Time"
table(actual = test$dv_not_on_time, predicted = pred_test)
```

Use `final_tree` (57 leaves) for accuracy. `display_tree` is only the plotted top of it. `tree_no_slack` and `tree_late` are the robustness trees.

### Outputs (`output/08_*`)

| File | What it is |
|---|---|
| `08_split_summary.csv` | Training/test table above |
| `08_tree_size.csv`, `08_cp_table.csv`, `08_cp_plot.png` | CP table and the cross-validated error plot |
| `08_variable_importance.csv` | Importance of all 21 predictors |
| `08_tree_plot.png` | The plotted tree (top 10 leaves) |
| `08_tree_leaves.csv` | Each plotted leaf: rule, lines and Not On Time share in training and test |
| `08_flag_rates.csv` | Not On Time share of flagged vs. other lines (plotted tree) |
| `08_robustness.csv` | Trees without slack and with DV B |
| `08_tree_print.txt` | Text print of the plotted tree and the CP table |
| `08_tree_models.rds` | All fitted trees |
