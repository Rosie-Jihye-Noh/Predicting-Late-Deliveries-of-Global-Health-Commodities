# Decision Tree (3): Accuracy on the training & test data (Vishnu)
# Run from the share_for_team folder. Needs output/05_model_data.rds and output/08_tree_models.rds.

library(rpart)

m     <- readRDS("output/05_model_data.rds")
trees <- readRDS("output/08_tree_models.rds")

# Same time split as 08_decision_tree.R
train <- m[m$order_entry_date <  trees$cutoff, ]
test  <- m[m$order_entry_date >= trees$cutoff, ]
c(train = nrow(train), test = nrow(test))       # expected 23,346 and 4,604

# Predicted class as 0/1, where 1 = Not On Time (or Late for the DV B tree)
pred_class <- function(tree, data) {
  p <- predict(tree, data, type = "class")
  as.integer(p == levels(p)[2])
}
# Probabilities are re-weighted by the equal priors, but the ranking is unchanged, so AUC is still valid
pred_score <- function(tree, data) predict(tree, data, type = "prob")[, 2]

conf_mat <- function(actual, predicted) {
  table(Actual    = factor(actual,    levels = c(0, 1), labels = c("On Time", "Not On Time")),
        Predicted = factor(predicted, levels = c(0, 1), labels = c("On Time", "Not On Time")))
}

# AUC by the rank (Mann-Whitney) formula
auc <- function(actual, score) {
  r  <- rank(score)
  n1 <- sum(actual == 1); n0 <- sum(actual == 0)
  (sum(r[actual == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

metrics <- function(actual, predicted, score) {
  TP <- sum(predicted == 1 & actual == 1); FN <- sum(predicted == 0 & actual == 1)
  FP <- sum(predicted == 1 & actual == 0); TN <- sum(predicted == 0 & actual == 0)
  recall    <- TP / (TP + FN)
  precision <- if (TP + FP > 0) TP / (TP + FP) else NA
  c(Lines             = length(actual),
    Actual_rate       = mean(actual),
    TP = TP, FN = FN, FP = FP, TN = TN,
    Accuracy          = (TP + TN) / length(actual),
    Baseline_accuracy = mean(actual == 0),             # accuracy of always predicting "On Time"
    Recall            = recall,
    Specificity       = TN / (TN + FP),
    Precision         = precision,
    F1                = 2 * precision * recall / (precision + recall),
    Balanced_accuracy = (recall + TN / (TN + FP)) / 2,
    Flagged_share     = mean(predicted == 1),
    AUC               = auc(actual, score))
}

evaluate <- function(name, tree, outcome) {
  rows <- lapply(list(Training = train, Test = test), function(d)
    metrics(d[[outcome]], pred_class(tree, d), pred_score(tree, d)))
  data.frame(Model = name, Set = names(rows), do.call(rbind, rows), row.names = NULL)
}

# Main model
pred_train <- pred_class(trees$final_tree, train)
pred_test  <- pred_class(trees$final_tree, test)

cm_train <- conf_mat(train$dv_not_on_time, pred_train)
cm_test  <- conf_mat(test$dv_not_on_time,  pred_test)
cm_train
cm_test

main_tbl <- evaluate("Main: Not On Time, all 21 predictors", trees$final_tree, "dv_not_on_time")
print(cbind(main_tbl[, 1:2], round(main_tbl[, -(1:2)], 3)), row.names = FALSE)

# Overfitting check: negative values mean the tree does worse on test
gap <- main_tbl[main_tbl$Set == "Test",     c("Accuracy", "Recall", "Specificity", "Precision", "F1", "AUC")] -
       main_tbl[main_tbl$Set == "Training", c("Accuracy", "Recall", "Specificity", "Precision", "F1", "AUC")]
rownames(gap) <- "Test - Training"
round(gap, 3)

# Robustness trees
all_tbl <- rbind(main_tbl,
                 evaluate("Without supplier slack", trees$tree_no_slack, "dv_not_on_time"),
                 evaluate("DV B: late only",        trees$tree_late,     "dv_late_only"))
all_tbl_round <- cbind(all_tbl[, 1:2], round(all_tbl[, -(1:2)], 3))
print(all_tbl_round[, c("Model", "Set", "Accuracy", "Baseline_accuracy", "Recall",
                        "Specificity", "Precision", "F1", "AUC")], row.names = FALSE)

# Chart: training vs. test
key <- c("Accuracy", "Recall", "Specificity", "Precision", "AUC")
mat <- as.matrix(main_tbl[, key]); rownames(mat) <- main_tbl$Set
png("output/09_accuracy_chart.png", width = 1800, height = 1100, res = 200)
par(mar = c(4, 4.5, 3, 1))
bp <- barplot(mat, beside = TRUE, col = c("#14213D", "#B8621B"), border = NA, ylim = c(0, 1.08),
              names.arg = key, ylab = "Share", las = 1,
              main = "Decision tree (final_tree): training vs. test", cex.main = 1)
text(bp, mat + 0.035, sprintf("%.2f", mat), cex = 0.75)
abline(h = main_tbl$Baseline_accuracy[main_tbl$Set == "Test"], lty = 2, col = "grey40")
legend("topright", bty = "n", cex = 0.85, fill = c("#14213D", "#B8621B", NA), border = NA,
       lty = c(NA, NA, 2), col = c(NA, NA, "grey40"),
       legend = c("Training", "Test", "Test baseline accuracy (always On Time)"))
dev.off()

# Save
cm_long <- rbind(data.frame(Set = "Training", as.data.frame(cm_train)),
                 data.frame(Set = "Test",     as.data.frame(cm_test)))
write.csv(cm_long,        "output/09_confusion_matrices.csv", row.names = FALSE)
write.csv(main_tbl,       "output/09_accuracy_main.csv",      row.names = FALSE)
write.csv(all_tbl_round,  "output/09_accuracy_all_trees.csv", row.names = FALSE)
write.csv(round(gap, 3),  "output/09_train_test_gap.csv",     row.names = FALSE)

sink("output/09_accuracy_print.txt")
cat("Decision tree accuracy (final_tree, 57 leaves). Positive class = Not On Time.\n\n")
cat("Confusion matrix - TRAINING\n"); print(cm_train)
cat("\nConfusion matrix - TEST\n");   print(cm_test)
cat("\nMetrics\n"); print(cbind(main_tbl[, 2, drop = FALSE], round(main_tbl[, -(1:2)], 3)), row.names = FALSE)
cat("\nTest minus training\n"); print(round(gap, 3), row.names = FALSE)
cat("\nAll trees\n"); print(all_tbl_round, row.names = FALSE)
sink()
