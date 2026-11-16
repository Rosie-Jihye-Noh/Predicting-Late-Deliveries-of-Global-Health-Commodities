# ============================================================
# BUAN6356 Group Project - Step G: Decision Tree (Aarushi)
#   1) Split the data by time: train on earlier orders, test on later ones
#   2) Grow a classification tree on the training data and display basic results
#   3) Plot the tree and make the tables used for the interpretation
# Accuracy on the training and test data (Decision Tree part 3) is Vishnu's part:
#   load output/08_tree_models.rds and use final_tree (see README, section 7)
# Packages: rpart (comes with R) and rpart.plot (run install.packages("rpart.plot") once)
# ============================================================

setwd("C:/BIZANwR")   # <- CHANGE to the folder where you saved these files
library(rpart)
library(rpart.plot)

m <- readRDS("output/05_model_data.rds")   # 27,950 rows from 05_preprocess.R

# ---- 1. Split by time ----
# Orders entered before 2022 = training, 2022 onward = test (cut-off from README section 4).
# All lines of an order share one entry date, so no order is split across the two sets.
cutoff <- as.Date("2022-01-01")
train <- m[m$order_entry_date <  cutoff, ]
test  <- m[m$order_entry_date >= cutoff, ]
length(intersect(train$order_number, test$order_number))   # expected 0

split_tbl <- data.frame(
  Set            = c("Training", "Test"),
  First_entry    = c(min(train$order_entry_date), min(test$order_entry_date)),
  Last_entry     = c(max(train$order_entry_date), max(test$order_entry_date)),
  Lines          = c(nrow(train), nrow(test)),
  Share_of_lines = round(c(nrow(train), nrow(test)) / nrow(m), 3),
  Orders         = c(length(unique(train$order_number)), length(unique(test$order_number))),
  Not_on_time    = c(sum(train$dv_not_on_time), sum(test$dv_not_on_time)),
  Not_on_time_rate = round(c(mean(train$dv_not_on_time), mean(test$dv_not_on_time)), 3))
split_tbl                                  # expected 23,346 (11.6%) and 4,604 (10.3%)

# ---- 2. Grow the tree ----
# Outcome as a factor, so rpart builds a classification tree
to_y <- function(x) factor(x, levels = c(0, 1), labels = c("On Time", "Not On Time"))
train$y <- to_y(train$dv_not_on_time)
test$y  <- to_y(test$dv_not_on_time)

# The 21 predictors on their original scale (the log versions are for Logistic Regression only)
predictors <- c("ordered_qty", "unit_price", "line_value", "lines_per_order",
                "planned_lead", "request_gap", "usaid_approval_days", "po_processing_days",
                "entry_to_po", "days_left_at_po", "slack",
                "order_type", "tlp", "transport", "task_order", "product", "country",
                "framework", "funding", "vendor_inco", "dest_inco")
f <- reformulate(predictors, response = "y")

# Cross-validation folds by order: all lines of one order go to the same fold.
# With random folds, lines of the same order sit on both sides and CV looks too good.
set.seed(6356)
orders <- unique(train$order_number)
order_fold <- sample(rep(1:10, length.out = length(orders)))
train_fold <- order_fold[match(train$order_number, orders)]

# Settings
#   prior = c(0.5, 0.5): only 11.6% of training lines are Not On Time. With the default
#     (prior = class shares), no split ever makes Not On Time the majority, so the tree
#     predicts "On Time" for every line (0 splits). Equal priors weigh the two classes
#     equally, the same as counting each missed Not On Time line about 7.7 times.
#   cp = 0.0005: grow a large tree first, then prune it back using cross-validation
#   minbucket = 50: every leaf holds at least 50 training lines
full_tree <- rpart(f, data = train, method = "class",
                   parms = list(prior = c(0.5, 0.5), split = "gini"),
                   control = rpart.control(cp = 0.0005, minbucket = 50, xval = train_fold))

# Prune with the 1-SE rule: the smallest tree whose CV error is within
# one standard error of the lowest CV error
cpt    <- full_tree$cptable
best   <- which.min(cpt[, "xerror"])
one_se <- which(cpt[, "xerror"] <= cpt[best, "xerror"] + cpt[best, "xstd"])[1]
final_tree <- prune(full_tree, cp = cpt[one_se, "CP"])

n_leaves <- function(tree) sum(tree$frame$var == "<leaf>")
tree_size <- data.frame(
  Tree   = c("Full tree", "Lowest CV error", "Final tree (1-SE rule)"),
  CP     = signif(c(min(cpt[, "CP"]), cpt[best, "CP"], cpt[one_se, "CP"]), 3),
  Splits = c(max(cpt[, "nsplit"]), cpt[best, "nsplit"], cpt[one_se, "nsplit"]),
  Leaves = c(max(cpt[, "nsplit"]), cpt[best, "nsplit"], cpt[one_se, "nsplit"]) + 1,
  CV_rel_error = round(c(cpt[nrow(cpt), "xerror"], cpt[best, "xerror"], cpt[one_se, "xerror"]), 3))
tree_size

# Basic results
printcp(final_tree)                        # CP table of the final tree
c(splits = nrow(final_tree$frame) - n_leaves(final_tree), leaves = n_leaves(final_tree))

labels <- c(ordered_qty = "Ordered quantity", unit_price = "Unit price", line_value = "Line value",
            lines_per_order = "Lines per order", planned_lead = "Planned lead time",
            request_gap = "Promise vs. request", usaid_approval_days = "USAID approval time",
            po_processing_days = "PO processing time", entry_to_po = "Entry to PO",
            days_left_at_po = "Days left at PO", slack = "Supplier slack",
            order_type = "Order type", tlp = "TLP indicator", transport = "Transport mode",
            task_order = "Task order", product = "Product category", country = "Country",
            framework = "Framework contract", funding = "Funding source",
            vendor_inco = "Vendor incoterm", dest_inco = "Destination incoterm")

imp <- final_tree$variable.importance
importance_tbl <- data.frame(Variable = unname(labels[names(imp)]), Column = names(imp),
                             Importance = round(100 * imp / sum(imp), 1), row.names = NULL)
importance_tbl                             # share of the total improvement, adds to 100

# ---- 3. Plot the tree ----
# The final tree has too many leaves to read on one slide. Pruning only removes the
# lowest splits, so its top splits are the same at every size. For the plot, keep the
# top 9 splits (10 leaves) of the final tree.
display_tree <- prune(final_tree, cp = cpt[max(which(cpt[, "nsplit"] <= 9)), "CP"])
print(display_tree)

# With equal priors, the probabilities rpart prints are re-weighted, not real shares.
# So the plot and tables show each node's actual Not On Time rate in the training data.
node_rates <- function(tree, data) {
  leaf  <- rpart.predict(tree, newdata = data, nn = TRUE)$nn   # leaf node of each line
  nodes <- as.numeric(rownames(tree$frame))
  t(sapply(nodes, function(k) {
    up <- leaf
    while (any(up > k)) up[up > k] <- up[up > k] %/% 2        # walk each line up to depth of k
    inside <- up == k
    c(node = k, lines = sum(inside), rate = mean(data$dv_not_on_time[inside]))
  }))
}
train_rates <- node_rates(display_tree, train)
test_rates  <- node_rates(display_tree, test)
flagged <- display_tree$frame$yval == 2                        # predicted Not On Time

# Box text: prediction, Not On Time share, number of training lines
node_label <- function(x, labs, digits, varlen)
  sprintf("%s\n%.0f%%\n%s", ifelse(flagged, "FLAG", "on time"),
          100 * train_rates[, "rate"], format(train_rates[, "lines"], big.mark = ","))

# Short country codes keep the split labels readable on a slide
country_code <- c("Other" = "Other", "Mozambique" = "MOZ", "Congo DRC" = "DRC", "Nigeria" = "NGA",
                  "Zambia" = "ZMB", "Haiti" = "HTI", "Uganda" = "UGA", "Tanzania" = "TZA",
                  "Ethiopia" = "ETH", "Zimbabwe" = "ZWE", "Rwanda" = "RWA", "Cameroon" = "CMR",
                  "Côte d'Ivoire" = "CIV")
split_label <- function(x, labs, digits, varlen, faclen) {
  for (v in names(labels)) labs <- sub(paste0("^", v, " "), paste0(labels[[v]], " "), labs)
  for (cn in names(country_code)) labs <- gsub(cn, country_code[[cn]], labs, fixed = TRUE)
  labs <- gsub(",", ", ", labs)
  sapply(labs, function(s) paste(strwrap(s, width = 38), collapse = "\n"))
}

png("output/08_tree_plot.png", width = 3600, height = 1800, res = 300)
rpart.plot(display_tree, type = 4, extra = 0, under = FALSE, fallen.leaves = TRUE,
           node.fun = node_label, split.fun = split_label, faclen = 0, varlen = 0,
           box.col = ifelse(flagged, "#F2D3BC", "#C9D6E8"), border.col = "#14213D",
           split.box.col = "white", split.border.col = "#14213D", split.cex = 0.9,
           cex = 0.72, branch.col = "#14213D", col = "#14213D",
           shadow.col = 0, mar = c(0.5, 1.5, 0.5, 1.5))
dev.off()

# CP plot (cross-validated error by tree size)
png("output/08_cp_plot.png", width = 1800, height = 1100, res = 200)
par(mar = c(4.5, 4.5, 3, 1))
plot(cpt[, "nsplit"] + 1, cpt[, "xerror"], type = "l", col = "#14213D", lwd = 2, log = "x",
     xlab = "Number of leaves (log scale)", ylab = "Cross-validated relative error",
     main = "Cross-validated error by tree size (10 folds, grouped by order)", cex.main = 1)
abline(h = cpt[best, "xerror"] + cpt[best, "xstd"], lty = 2, col = "#B8621B")
points(cpt[c(best, one_se), "nsplit"] + 1, cpt[c(best, one_se), "xerror"],
       pch = 19, col = c("#14213D", "#B8621B"), cex = 1.4)
legend("topright", bty = "n", cex = 0.9, pch = c(19, 19, NA), lty = c(NA, NA, 2),
       col = c("#14213D", "#B8621B", "#B8621B"),
       legend = c(sprintf("Lowest CV error: %d leaves", cpt[best, "nsplit"] + 1),
                  sprintf("Final tree (1-SE rule): %d leaves", cpt[one_se, "nsplit"] + 1),
                  "Lowest error + 1 standard error"))
dev.off()

# Leaf table: the rule that leads to each leaf, ranked by Not On Time rate
leaf_nodes <- as.numeric(rownames(display_tree$frame))[display_tree$frame$var == "<leaf>"]
rules <- path.rpart(display_tree, leaf_nodes, print.it = FALSE)
pretty_rule <- function(p) {
  p <- p[-1]                                                   # drop "root"
  for (v in names(labels)) p <- sub(paste0("^", v), labels[[v]], p)
  paste(gsub(",", ", ", p), collapse = "  AND  ")
}
pos <- match(leaf_nodes, train_rates[, "node"])
leaf_tbl <- data.frame(
  Node            = leaf_nodes,
  Rule            = sapply(rules, pretty_rule),
  Prediction      = ifelse(flagged[pos], "Not On Time (flag)", "On Time"),
  Train_lines     = train_rates[pos, "lines"],
  Train_rate      = round(train_rates[pos, "rate"], 3),
  Test_lines      = test_rates[pos, "lines"],
  Test_rate       = round(test_rates[pos, "rate"], 3),
  row.names = NULL)
leaf_tbl <- leaf_tbl[order(-leaf_tbl$Train_rate), ]
print(leaf_tbl[, -2], row.names = FALSE)

# Not On Time share of the lines the plotted tree flags vs. does not flag
# (descriptive; accuracy and recall of the final tree are in Vishnu's part)
flag_rate <- function(data) {
  flag <- predict(display_tree, data, type = "class") == "Not On Time"
  c(flagged_lines = sum(flag), flagged_rate = mean(data$dv_not_on_time[flag]),
    other_rate = mean(data$dv_not_on_time[!flag]))
}
flag_tbl <- data.frame(Set = c("Training", "Test"), round(rbind(flag_rate(train), flag_rate(test)), 3))
flag_tbl

# ---- Robustness: same steps without slack, and with DV B (late only) ----
# Slack may leak if the supplier's ready date is updated after PO release (README section 5).
grow_prune <- function(formula, data, prior) {
  t <- rpart(formula, data = data, method = "class", parms = list(prior = prior, split = "gini"),
             control = rpart.control(cp = 0.0005, minbucket = 50, xval = train_fold))
  ct <- t$cptable; b <- which.min(ct[, "xerror"])
  prune(t, cp = ct[which(ct[, "xerror"] <= ct[b, "xerror"] + ct[b, "xstd"])[1], "CP"])
}
summarize_tree <- function(name, tree) {
  vi <- tree$variable.importance
  data.frame(Model = name, Leaves = n_leaves(tree),
             First_split = unname(labels[as.character(tree$frame$var[1])]),
             Top_3_variables = paste(labels[names(vi)[1:3]], collapse = ", "))
}
tree_no_slack <- grow_prune(reformulate(setdiff(predictors, "slack"), response = "y"), train, c(0.5, 0.5))
train$y_late  <- factor(train$dv_late_only, levels = c(0, 1), labels = c("Not late", "Late"))
tree_late     <- grow_prune(reformulate(predictors, response = "y_late"), train, c(0.5, 0.5))
robust_tbl <- rbind(summarize_tree("Main: Not On Time, all 21 predictors", final_tree),
                    summarize_tree("Without supplier slack", tree_no_slack),
                    summarize_tree("DV B: late only", tree_late))
robust_tbl

# ---- Save ----
dir.create("output", showWarnings = FALSE)
write.csv(split_tbl,      "output/08_split_summary.csv",       row.names = FALSE)
write.csv(tree_size,      "output/08_tree_size.csv",           row.names = FALSE)
write.csv(cpt,            "output/08_cp_table.csv",            row.names = FALSE)
write.csv(importance_tbl, "output/08_variable_importance.csv", row.names = FALSE)
write.csv(leaf_tbl,       "output/08_tree_leaves.csv",         row.names = FALSE)
write.csv(flag_tbl,       "output/08_flag_rates.csv",          row.names = FALSE)
write.csv(robust_tbl,     "output/08_robustness.csv",          row.names = FALSE)
sink("output/08_tree_print.txt")
cat("Plotted tree (top 9 splits of the final tree); probabilities use equal priors\n\n")
print(display_tree)
cat("\n\nCP table of the final tree\n\n")
printcp(final_tree)
sink()
# For Vishnu (accuracy on training and test data): everything needed in one file
saveRDS(list(final_tree = final_tree, display_tree = display_tree, cutoff = cutoff,
             predictors = predictors, tree_no_slack = tree_no_slack, tree_late = tree_late),
        "output/08_tree_models.rds")
