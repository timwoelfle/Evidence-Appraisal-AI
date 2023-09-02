source("../../../src/results_functions_precis2.r") # items

# Experiment 1: Claude
results_1 = read.csv("../claude2/results.csv", row.names = 1, na.strings = NULL)
results_1[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_1$llm_scores), ", ", fixed=T), as.character))
# Experiment 2: Claude (rep)
results_2 = read.csv("../claude2_rep/results.csv", row.names = 1, na.strings = NULL)
results_2[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_2$llm_scores), ", ", fixed=T), as.character))
# Experiment 3: GPT
results_3 = read.csv("../gpt3.5/results.csv", row.names = 1, na.strings = NULL)
results_3[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_3$llm_scores), ", ", fixed=T), as.character))
results_3 = results_3[rownames(results_1),]
rownames(results_3) = rownames(results_1)
results_3[is.na(results_3)] = "NA" # because some papers are missing in results_3
# Experiment 4: GPT (rep)
results_4 = read.csv("../gpt3.5_rep/results.csv", row.names = 1, na.strings = NULL)
results_4[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_4$llm_scores), ", ", fixed=T), as.character))
results_4 = results_4[rownames(results_1),]
rownames(results_4) = rownames(results_1)
results_4[is.na(results_4)] = "NA" # because some papers are missing in results_4
# Experiment 5: Claude (GPT-prompt)
results_5 = read.csv("../claude2-gpt-prompt/results.csv", row.names = 1, na.strings = NULL)
results_5[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_5$llm_scores), ", ", fixed=T), as.character))

stopifnot((rownames(results_1) == rownames(results_2)) & (rownames(results_1) == rownames(results_3)) & (rownames(results_1) == rownames(results_4)) & (rownames(results_1) == rownames(results_5)))
stopifnot((items %in% colnames(results_1)) & (items %in% colnames(results_2)) & (items %in% colnames(results_3)) & (items %in% colnames(results_4)) & (items %in% colnames(results_5)))

# Combine results
results = data.frame()
for (row in rownames(results_1)) {
  self_consistency = sapply(items, function(item) table(c(results_1[row, item], results_2[row, item], results_3[row, item], results_4[row, item], results_5[row, item])))
  self_consistency = sapply(self_consistency, function(table) names(which(table >= 3)))
  results[row, items] = ifelse(sapply(self_consistency, length), self_consistency, "deferred")
}

write.csv(results, "results_self_consistency.csv")
