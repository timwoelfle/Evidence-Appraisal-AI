source("../../../src/results_functions_prisma_amstar.r") # prisma, amstar

items = c(amstar, prisma)

rater1 = read.csv("../../../data/PRISMA-AMSTAR/rater1.csv", row.names = 1, na.strings = NULL)

results = read.csv("../llm-self-consistency-5_prisma-amstar/results_self_consistency.csv", row.names = 1, na.strings = NULL)

# Combine results
for (row in rownames(results)) {
  results[row, items] = ifelse(results[row, items] == rater1[row, items], results[row, items], "deferred")
}
results = results[items]

write.csv(results, "results_rater1_llm_combined.csv")
