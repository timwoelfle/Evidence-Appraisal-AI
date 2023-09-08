source("../../../src/results_functions_precis2.r") # items

rater1 = read.csv("../../../data/PRECIS-2/rater1.csv", row.names = 1, na.strings = NULL, check.names = F)
rater2 = read.csv("../../../data/PRECIS-2/rater2.csv", row.names = 1, na.strings = NULL, check.names = F)

# Combine results
results = data.frame()
for (row in rownames(rater1)) {
  results[row, items] = ifelse(rater1[row, items] == rater2[row, items], rater1[row, items], "deferred")
}

write.csv(results, "results_rater1_rater2_combined.csv")
