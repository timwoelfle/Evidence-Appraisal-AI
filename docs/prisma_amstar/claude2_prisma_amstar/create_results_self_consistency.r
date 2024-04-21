source("../../../src/results_functions_prisma_amstar.r") # prisma, amstar

items = c(amstar, prisma)

results_1st = read.csv("results.csv", row.names = 1)
results_1st[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_1st$llm_scores), ", ", fixed=T), as.character))

results_2nd = read.csv("../claude2_prisma_amstar_rep/results.csv", row.names = 1)
results_2nd[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_2nd$llm_scores), ", ", fixed=T), as.character))

results_1st = results_1st[rownames(results_1st) %in% rownames(results_2nd),]
results_2nd = results_2nd[rownames(results_2nd) %in% rownames(results_1st),]

# Combine results
results = data.frame()
for (row in rownames(results_1st)) {
  results[row, items] = ifelse(results_1st[row, items] == results_2nd[row, items], results_1st[row, items], "deferred")
}

write.csv(results, "results_self_consistency.csv")
