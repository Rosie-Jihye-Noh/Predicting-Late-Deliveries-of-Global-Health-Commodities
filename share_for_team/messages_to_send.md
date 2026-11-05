# Messages to send (copy and paste)

---

## 1. To the whole team

Hi team! My part (Part 1, data exploration) is ready for you to use.

**Files:** I’m sharing a folder `share_for_team`. Start with `README.md`. It has:
- the final modeling data: `output/05_model_data.rds` (27,950 order lines, 29 columns, no missing values)
- R scripts 01–06 that rebuild it from the original CSV (base R only; just change the `setwd()` line to your folder)
- the data dictionary, Table 1 statistics, box plots, and the pre-processing rationale (README section 6)

**Slides:** `Part1_Data_Exploration.pptx` (attached). 18 slides: intro, outcome, variables, Table 1, outliers, pre-processing. Speaker notes are included.

**Key decisions, so we all build on the same data:**
- Outcome: `dv_not_on_time` = 1 if delivered outside the program’s official window (more than 14 days early or more than 7 days late versus the agreed date): 11.4%. Robustness check: `dv_late_only` (more than 7 days late): 10.4%.
- Prediction point: PO release. All 21 predictors are known by then; post-PO columns are excluded to avoid leakage.
- Orders entered from Oct 2017 only (the program restructured at the start of FY2018).

**For Decision Tree / Logistic Regression (please read section 4 of the README):**
- The proposal says we split by time (train on earlier orders, test on later ones), not at random.
- If you resample, do it on training data only.
- Report recall for Not On Time and the confusion matrix, not just accuracy. Predicting "on time" for everything already gives about 89% accuracy.
- For Logistic Regression only: use the `log_` size variables. Watch two overlaps: `entry_to_po` = `planned_lead` − `days_left_at_po` exactly, so drop one of the three; and `log_line_value` ≈ `log_ordered_qty` + `log_unit_price`, so don’t use all three.

Let me know if anything is unclear!

---

## 2. To Indra

Hi Indra! Since outliers and pre-processing are your part, I’ve drafted them so we can build our Part 1 slides together. Could you review and validate them? That way it’s still your section, and you can present it (slides 14–18).

**Could you please check:**
1. **Reproduce:** run scripts 03 → 05 on your computer (change `setwd()` to your folder). Do you get 28,556 → 28,458 → 27,950 rows in `output/05_preprocess_log.csv`?
2. **Review the four decisions** in section 6 of `README.md` (rules and evidence). Do you agree with them, and did I miss any error rule?
   - remove 98 impossible values
   - log the 4 size variables for Logistic Regression only
   - keep real extreme values
   - remove 508 lines with missing values
3. **Robustness check (optional but useful):** do the results change if we cap extreme values at the 99th percentile, or keep all periods with a "start-up period" dummy?
4. **Slides 14–18:** anything you would change or explain differently?

Thank you!
