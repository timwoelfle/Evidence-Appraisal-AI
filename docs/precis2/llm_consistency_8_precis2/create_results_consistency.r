source("../../../src/results_functions_precis2.r") # precis2

items = precis2

# gpt3.5_precis2
results_1 = read.csv("../gpt3.5_precis2/results.csv", row.names = 1, na.strings = NULL)
results_1[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_1$llm_scores), ", ", fixed=T), as.character))

# gpt3.5_precis2_rep
results_2 = read.csv("../gpt3.5_precis2_rep/results.csv", row.names = 1, na.strings = NULL)
results_2[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_2$llm_scores), ", ", fixed=T), as.character))

# claude2_precis2
results_3 = read.csv("../claude2_precis2/results.csv", row.names = 1, na.strings = NULL)
results_3[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_3$llm_scores), ", ", fixed=T), as.character))

# Some are missing for gpt3.5, create empty rows
results_1 = results_1[rownames(results_3),]
rownames(results_1) = rownames(results_3)
results_2 = results_2[rownames(results_3),]
rownames(results_2) = rownames(results_3)

# claude2_precis2_rep
results_4 = read.csv("../claude2_precis2_rep/results.csv", row.names = 1, na.strings = NULL)
results_4[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_4$llm_scores), ", ", fixed=T), as.character))

# gpt4_precis2
results_5 = read.csv("../gpt4_precis2/results.csv", row.names = 1, na.strings = NULL)
results_5[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_5$llm_scores), ", ", fixed=T), as.character))

# claude3_opus_precis2
results_6 = read.csv("../claude3_opus_precis2/results.csv", row.names = 1, na.strings = NULL)
results_6[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_6$llm_scores), ", ", fixed=T), as.character))

# claude3_opus_precis2_rep
results_7 = read.csv("../claude3_opus_precis2_rep/results.csv", row.names = 1, na.strings = NULL)
results_7[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_7$llm_scores), ", ", fixed=T), as.character))

# mixtral8x22b_precis2
results_8 = read.csv("../mixtral8x22b_precis2/results.csv", row.names = 1, na.strings = NULL)
results_8[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_8$llm_scores), ", ", fixed=T), as.character))
results_8 = results_8[rownames(results_8),]
rownames(results_8) = rownames(results_8)

# mixtral8x22b_precis2_rep
results_9 = read.csv("../mixtral8x22b_precis2_rep/results.csv", row.names = 1, na.strings = NULL)
results_9[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_9$llm_scores), ", ", fixed=T), as.character))
results_9 = results_9[rownames(results_8),]
rownames(results_9) = rownames(results_8)


stopifnot((rownames(results_1) == rownames(results_2)) & (rownames(results_1) == rownames(results_3)) & (rownames(results_1) == rownames(results_4)) & (rownames(results_1) == rownames(results_5)) & (rownames(results_1) == rownames(results_6)) & (rownames(results_1) == rownames(results_7)) & (rownames(results_1) == rownames(results_8)) & (rownames(results_1) == rownames(results_9)))
stopifnot((items %in% colnames(results_1)) & (items %in% colnames(results_2)) & (items %in% colnames(results_3)) & (items %in% colnames(results_4)) & (items %in% colnames(results_5)) & (items %in% colnames(results_6)) & (items %in% colnames(results_7)) & (items %in% colnames(results_8)) & (items %in% colnames(results_9)))

# Combine results
results = data.frame()
for (row in rownames(results_1)) {
  # Compare self_consistency after pooling 1/2 and 4/5
  self_consistency_pooled = sapply(unname(items), function(item) table(factorize_pooled(c(results_1[row, item], results_2[row, item], results_3[row, item], results_4[row, item], results_5[row, item], results_6[row, item], results_7[row, item], results_8[row, item], results_9[row, item]))))
  n_scores = unname(colSums(self_consistency_pooled)[1]) # Some rows might be missing because the LLM was not successful for them (true NA, not "NA")
  # Set threshold to n_scores/2+x but max. n_scores - i.e. for 9 scores (maximum if no experiment is missing), thresholds range from 5 to 9; for 7 scores (i.e. 2 experiments missing), thresholds range from 4 to 7
  self_consistency_pooled = sapply(unname(items), function(item) names(which(self_consistency_pooled[, item] >= min(n_scores / 2 + 3, n_scores))))
  
  # For 1/2 and 4/5 select whichever is more frequent or in case of tie select 2 or 4
  self_consistency = sapply(items, function(item) table(factorize(c(results_1[row, item], results_2[row, item], results_3[row, item], results_4[row, item], results_5[row, item], results_6[row, item], results_7[row, item], results_8[row, item], results_9[row, item]))))
  self_consistency_pooled = ifelse(self_consistency_pooled=="1/2", ifelse(self_consistency["2",]>=self_consistency["1",], "2", "1"), self_consistency_pooled)
  self_consistency_pooled = ifelse(self_consistency_pooled=="4/5", ifelse(self_consistency["4",]>=self_consistency["5",], "4", "5"), self_consistency_pooled)
  results[row, items] = ifelse(sapply(self_consistency_pooled, length)==1, self_consistency_pooled, "deferred")
}

write.csv(results, "results.csv")
