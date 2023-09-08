source("../../../src/results_functions_prisma_amstar.r") # prisma, amstar

items = c(amstar, prisma)

rater1 = read.csv("../../../data/PRISMA-AMSTAR/rater1.csv", row.names = 1, na.strings = NULL)
rater2 = read.csv("../../../data/PRISMA-AMSTAR/rater2.csv", row.names = 1, na.strings = NULL)

# Combine results
results = data.frame()
for (row in rownames(rater2)) {
  results[row, items] = ifelse(rater1[row, items] == rater2[row, items], rater1[row, items], "deferred")
}

write.csv(results, "results_rater1_rater2_combined.csv")
