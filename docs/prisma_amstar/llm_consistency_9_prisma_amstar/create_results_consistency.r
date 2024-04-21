source("../../../src/results_functions_prisma_amstar.r") # prisma, amstar

items = c(amstar, prisma)

# gpt3.5
results_gpt3.5_amstar_1 = read.csv("../gpt3.5_amstar/results.csv", row.names = 1, na.strings = NULL)
results_gpt3.5_amstar_1[amstar] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt3.5_amstar_1$llm_scores), ", ", fixed=T), as.character))
results_gpt3.5_prisma_1 = read.csv("../gpt3.5_prisma/results.csv", row.names = 1, na.strings = NULL)
results_gpt3.5_prisma_1[prisma] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt3.5_prisma_1$llm_scores), ", ", fixed=T), as.character))
results_1 = cbind(results_gpt3.5_amstar_1, results_gpt3.5_prisma_1[rownames(results_gpt3.5_amstar_1),])

# gpt3.5 rep
results_gpt3.5_amstar_2 = read.csv("../gpt3.5_amstar_rep/results.csv", row.names = 1, na.strings = NULL)
results_gpt3.5_amstar_2[amstar] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt3.5_amstar_2$llm_scores), ", ", fixed=T), as.character))
results_gpt3.5_prisma_2 = read.csv("../gpt3.5_prisma_rep/results.csv", row.names = 1, na.strings = NULL)
results_gpt3.5_prisma_2[prisma] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt3.5_prisma_2$llm_scores), ", ", fixed=T), as.character))
results_2 = cbind(results_gpt3.5_amstar_2, results_gpt3.5_prisma_2[rownames(results_gpt3.5_amstar_2),])

# claude2
results_3 = read.csv("../claude2_prisma_amstar/results.csv", row.names = 1, na.strings = NULL)
results_3[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_3$llm_scores), ", ", fixed=T), as.character))

# claude2 rep
results_4 = read.csv("../claude2_prisma_amstar_rep/results.csv", row.names = 1, na.strings = NULL)
results_4[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_4$llm_scores), ", ", fixed=T), as.character))

# gpt4
results_5 = read.csv("../gpt4_prisma_amstar/results.csv", row.names = 1, na.strings = NULL)
results_5[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_5$llm_scores), ", ", fixed=T), as.character))
results_5 = results_5[rownames(results_1),]
rownames(results_5) = rownames(results_1)

# claude3_opus
results_6 = read.csv("../claude3_opus_prisma_amstar/results.csv", row.names = 1, na.strings = NULL)
results_6[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_6$llm_scores), ", ", fixed=T), as.character))
results_6 = results_6[rownames(results_1),]
rownames(results_6) = rownames(results_1)

# claude3_opus rep
results_7 = read.csv("../claude3_opus_prisma_amstar_rep/results.csv", row.names = 1, na.strings = NULL)
results_7[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_7$llm_scores), ", ", fixed=T), as.character))
results_7 = results_7[rownames(results_1),]
rownames(results_7) = rownames(results_1)

# mixtral8x22b
results_8 = read.csv("../mixtral8x22b_prisma_amstar/results.csv", row.names = 1, na.strings = NULL)
results_8[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_8$llm_scores), ", ", fixed=T), as.character))
results_8 = results_8[rownames(results_1),]
rownames(results_8) = rownames(results_1)

# mixtral8x22b rep
results_9 = read.csv("../mixtral8x22b_prisma_amstar_rep/results.csv", row.names = 1, na.strings = NULL)
results_9[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_9$llm_scores), ", ", fixed=T), as.character))
results_9 = results_9[rownames(results_1),]
rownames(results_9) = rownames(results_1)


stopifnot((rownames(results_1) == rownames(results_2)) & (rownames(results_1) == rownames(results_3)) & (rownames(results_1) == rownames(results_4)) & (rownames(results_1) == rownames(results_5)) & (rownames(results_1) == rownames(results_6)) & (rownames(results_1) == rownames(results_7)) & (rownames(results_1) == rownames(results_8)) & (rownames(results_1) == rownames(results_9)))
stopifnot((items %in% colnames(results_1)) & (items %in% colnames(results_2)) & (items %in% colnames(results_3)) & (items %in% colnames(results_4)) & (items %in% colnames(results_5)) & (items %in% colnames(results_6)) & (items %in% colnames(results_7)) & (items %in% colnames(results_8)) & (items %in% colnames(results_9)))

# Combine results
results = data.frame()
for (row in rownames(results_1)) {
  self_consistency = sapply(unname(items), function(item) table(factorize(c(results_1[row, item], results_2[row, item], results_3[row, item], results_4[row, item], results_5[row, item], results_6[row, item], results_7[row, item], results_8[row, item], results_9[row, item]))))
  n_scores = unname(colSums(self_consistency)[1]) # Some rows might be missing because the LLM was not successful for them (true NA, not "NA")
  # Set threshold to n_scores/2+x but max. n_scores - i.e. for 9 scores (maximum if no experiment is missing), thresholds range from 5 to 9; for 7 scores (i.e. 2 experiments missing), thresholds range from 4 to 7
  self_consistency = sapply(unname(items), function(item) names(which(self_consistency[, item] >= min(n_scores / 2 + 4, n_scores))))
  results[row, items] = ifelse(sapply(self_consistency, length)==1, self_consistency, "deferred")
}

write.csv(results, "results.csv")
