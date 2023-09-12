source("../../../src/results_functions_precis2.r") # items

rater1 = read.csv("../../../data/precis2/rater1.csv", row.names = 1, na.strings = NULL, check.names = F)

results = read.csv("../claude2-precis2/results.csv", row.names = 1)
results[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results$llm_scores), ", ", fixed=T), as.character))

# Combine results
for (row in rownames(results)) {
  results[row, items] = ifelse(results[row, items] == rater1[row, items], results[row, items], "deferred")
}
results = results[items]

write.csv(results, "results_rater1_llm_combined.csv")
