source("../../../src/results_functions_precis2.r") # items

rater1 = read.csv("../../../data/PRECIS-2/rater1.csv", row.names = 1, na.strings = NULL, check.names = F)

results = read.csv("../llm-self-consistency-5_precis2/results_self_consistency.csv", row.names = 1, na.strings = NULL, check.names = F)

# Combine results
for (row in rownames(results)) {
  results[row, items] = ifelse(results[row, items] == rater1[row, items], results[row, items], "deferred")
}

write.csv(results, "results_rater1_llm_combined.csv")
