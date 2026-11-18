# BUAN 6356 Group D - Logistic Regression (3): Training and test accuracy
# Author: Jeremiah Boban
# Run from share_for_team after 07_logistic_regression.R:
#   source("10_logistic_accuracy.R")  or  Rscript 10_logistic_accuracy.R
# Input: Ethan's saved prediction RDS files. Base R only.

paths <- c(Training = "output/07_train.rds", Test = "output/07_test.rds")
if (!all(file.exists(paths))) {
  stop("Run 07_logistic_regression.R from share_for_team to create output/07_train.rds and output/07_test.rds.")
}
sets <- lapply(paths, readRDS)

models <- data.frame(
  name = c("Main", "Without supplier slack", "Late only (DV B)"),
  outcome = c("dv_not_on_time", "dv_not_on_time", "dv_late_only"),
  probability = c("prob_not_on_time", "prob_no_slack", "prob_late_only")
)

evaluate <- function(actual, score, cutoffs, model, set) {
  stopifnot(length(actual) == length(score), all(actual %in% c(0, 1)),
            all(is.finite(score)), all(score >= 0 & score <= 1))
  positives <- sum(actual == 1)
  negatives <- sum(actual == 0)
  stopifnot(positives > 0, negatives > 0)

  # Average ranks give tied risk scores half credit.
  ranks <- rank(score)
  auc <- (sum(ranks[actual == 1]) - positives * (positives + 1) / 2) /
    (positives * negatives)

  rows <- lapply(names(cutoffs), function(rule) {
    cutoff <- cutoffs[[rule]]
    predicted <- as.integer(score > cutoff)  # lecture convention
    tp <- sum(actual == 1 & predicted == 1)
    fp <- sum(actual == 0 & predicted == 1)
    fn <- positives - tp
    tn <- negatives - fp
    recall <- tp / positives
    specificity <- tn / negatives

    data.frame(Model = model, Set = set, Rule = rule, Cutoff = cutoff,
               Lines = length(actual), Actual_rate = mean(actual),
               TN = tn, FP = fp, FN = fn, TP = tp,
               Accuracy = (tp + tn) / length(actual),
               Baseline_accuracy = mean(actual == 0),
               Recall = recall, Specificity = specificity,
               Precision = if (tp + fp > 0) tp / (tp + fp) else NA_real_,
               Balanced_accuracy = (recall + specificity) / 2,
               Flagged_share = mean(predicted), AUC = auc)
  })
  do.call(rbind, rows)
}

metrics <- do.call(rbind, lapply(seq_len(nrow(models)), function(i) {
  specification <- models[i, ]
  # The lower cutoff uses only the training outcome share. Use its full
  # precision for both sets; for DV B use the training late-only share.
  cutoffs <- c("Lecture default" = 0.50,
               "Training prevalence" = mean(sets$Training[[specification$outcome]]))

  rows <- lapply(names(sets), function(set) {
    data <- sets[[set]]
    evaluate(data[[specification$outcome]], data[[specification$probability]],
             cutoffs, specification$name, set)
  })
  do.call(rbind, rows)
}))

# Actual classes are rows and predicted classes are columns, as in 09.
labels <- c("On Time", "Not On Time")
confusion <- do.call(rbind, lapply(seq_len(nrow(metrics)), function(i) {
  row <- metrics[i, ]
  class_labels <- if (row$Model == "Late only (DV B)") c("Within late limit", "Late") else labels
  data.frame(Model = row$Model, Set = row$Set, Rule = row$Rule, Cutoff = row$Cutoff,
             Actual = rep(class_labels, each = 2),
             Predicted = rep(class_labels, times = 2),
             Count = c(row$TN, row$FP, row$FN, row$TP))
}))

write.csv(metrics, "output/10_logistic_accuracy.csv", row.names = FALSE)
write.csv(confusion, "output/10_logistic_confusion_matrices.csv", row.names = FALSE)

main <- metrics[metrics$Model == "Main", ]
cat("Main logistic regression: positive class = Not On Time\n")
for (i in seq_len(nrow(main))) {
  row <- main[i, ]
  cat(sprintf("\n%s | %s | cutoff %.5f\n", row$Set, row$Rule, row$Cutoff))
  print(matrix(c(row$TN, row$FP, row$FN, row$TP), nrow = 2, byrow = TRUE,
               dimnames = list(Actual = labels, Predicted = labels)))
}

cat("\nMetrics (proportions, except line counts)\n")
report <- metrics[c("Model", "Set", "Rule", "Cutoff", "Lines", "Accuracy",
                    "Baseline_accuracy", "Recall", "Precision", "Flagged_share", "AUC")]
report[4:ncol(report)] <- lapply(report[4:ncol(report)], round, digits = 4)
print(report, row.names = FALSE)
