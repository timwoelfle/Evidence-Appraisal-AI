source("../../../src/results_functions_prisma_amstar.r") # prisma, amstar

items = c(amstar, prisma)

rater1 = read.csv("../../../data/prisma-amstar/rater1.csv", row.names = 1, na.strings = NULL)

results = read.csv("../gpt4-prisma-amstar/results.csv", row.names = 1)
results[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results$llm_scores), ", ", fixed=T), as.character))

# Combine results
for (row in rownames(results)) {
  results[row, items] = ifelse(results[row, items] == rater1[row, items], results[row, items], "deferred")
}
results = results[items]

write.csv(results, "results_rater1_llm_combined.csv")
