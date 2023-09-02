source("../../../src/results_functions_precis2.r") # items

results_1st = read.csv("results.csv", row.names = 1)
results_1st[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_1st$llm_scores), ", ", fixed=T), as.character))

results_2nd = read.csv("../gpt3.5_rep/results.csv", row.names = 1)
results_2nd[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_2nd$llm_scores), ", ", fixed=T), as.character))

# Combine results
results = data.frame()
for (row in rownames(results_1st)) {
  results[row, items] = ifelse(results_1st[row, items] == results_2nd[row, items], results_1st[row, items], "deferred")
}

write.csv(results, "results_self_consistency.csv")
