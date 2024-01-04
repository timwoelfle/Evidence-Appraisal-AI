source("../../../src/results_functions_precis2.r") # items

# Experiment 1: GPT-3.5
results_1 = read.csv("../gpt3.5-precis2/results.csv", row.names = 1, na.strings = NULL)
results_1[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_1$llm_scores), ", ", fixed=T), as.character))
# Experiment 2: GPT-3.5 (rep)
results_2 = read.csv("../gpt3.5-precis2-rep/results.csv", row.names = 1, na.strings = NULL)
results_2[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_2$llm_scores), ", ", fixed=T), as.character))

# Experiment 3: Claude-2-chat
results_3 = read.csv("../claude2-chat-precis2/results.csv", row.names = 1, na.strings = NULL)
results_3[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_3$llm_scores), ", ", fixed=T), as.character))
results_1 = results_1[rownames(results_3),]
rownames(results_1) = rownames(results_3)
results_1[is.na(results_1)] = "NA" # because some papers are missing in results_1
results_2 = results_2[rownames(results_3),]
rownames(results_2) = rownames(results_3)
results_2[is.na(results_2)] = "NA" # because some papers are missing in results_2
# Experiment 4: Claude-2-chat (rep)
results_4 = read.csv("../claude2-chat-precis2-rep/results.csv", row.names = 1, na.strings = NULL)
results_4[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_4$llm_scores), ", ", fixed=T), as.character))

# Experiment 5: Claude-2-chat-gpt-prompt
results_5 = read.csv("../claude2-chat-gpt-prompt-precis2/results.csv", row.names = 1, na.strings = NULL)
results_5[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_5$llm_scores), ", ", fixed=T), as.character))

# Experiment 6: Claude-2
results_6 = read.csv("../claude2-precis2/results.csv", row.names = 1, na.strings = NULL)
results_6[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_6$llm_scores), ", ", fixed=T), as.character))
# Experiment 7: Claude-2 (rep)
results_7 = read.csv("../claude2-precis2-rep/results.csv", row.names = 1, na.strings = NULL)
results_7[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_7$llm_scores), ", ", fixed=T), as.character))

# Experiment 8: GPT-4
results_8 = read.csv("../gpt4-precis2/results.csv", row.names = 1, na.strings = NULL)
results_8[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_8$llm_scores), ", ", fixed=T), as.character))

stopifnot((rownames(results_1) == rownames(results_2)) & (rownames(results_1) == rownames(results_3)) & (rownames(results_1) == rownames(results_4)) & (rownames(results_1) == rownames(results_5)) & (rownames(results_1) == rownames(results_6)) & (rownames(results_1) == rownames(results_7)) & (rownames(results_1) == rownames(results_8)))
stopifnot((items %in% colnames(results_1)) & (items %in% colnames(results_2)) & (items %in% colnames(results_3)) & (items %in% colnames(results_4)) & (items %in% colnames(results_5)) & (items %in% colnames(results_6)) & (items %in% colnames(results_7)) & (items %in% colnames(results_8)))

# Combine results
results = data.frame()
for (row in rownames(results_1)) {
  self_consistency = sapply(items, function(item) table(c(results_1[row, item], results_2[row, item], results_3[row, item], results_4[row, item], results_5[row, item], results_6[row, item], results_7[row, item], results_8[row, item])))
  self_consistency = sapply(self_consistency, function(table) names(which(table >= 6)))
  results[row, items] = ifelse(sapply(self_consistency, length), self_consistency, "deferred")
}

write.csv(results, "results.csv")
