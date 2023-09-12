source("../../../src/results_functions_prisma_amstar.r") # prisma, amstar

items = c(amstar, prisma)

# Experiment 1: GPT-3.5
results_gpt_amstar_1 = read.csv("../gpt3.5-amstar/results.csv", row.names = 1, na.strings = NULL)
results_gpt_amstar_1[amstar] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt_amstar_1$llm_scores), ", ", fixed=T), as.character))
results_gpt_prisma_1 = read.csv("../gpt3.5-prisma/results.csv", row.names = 1, na.strings = NULL)
results_gpt_prisma_1[prisma] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt_prisma_1$llm_scores), ", ", fixed=T), as.character))
results_1 = cbind(results_gpt_amstar_1, results_gpt_prisma_1[rownames(results_gpt_amstar_1),])
results_1[is.na(results_1)] = "NA" # because some papers are missing in results_gpt_prisma_1
# Experiment 2: GPT-3.5 (rep)
results_gpt_amstar_2 = read.csv("../gpt3.5-amstar-rep/results.csv", row.names = 1, na.strings = NULL)
results_gpt_amstar_2[amstar] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt_amstar_2$llm_scores), ", ", fixed=T), as.character))
results_gpt_prisma_2 = read.csv("../gpt3.5-prisma-rep/results.csv", row.names = 1, na.strings = NULL)
results_gpt_prisma_2[prisma] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt_prisma_2$llm_scores), ", ", fixed=T), as.character))
results_2 = cbind(results_gpt_amstar_2, results_gpt_prisma_2[rownames(results_gpt_amstar_2),])
results_2[is.na(results_2)] = "NA" # because some papers are missing in results_gpt_prisma_2

# Experiment 1: Claude-2-chat
results_3 = read.csv("../claude2-chat-prisma-amstar/results.csv", row.names = 1, na.strings = NULL)
results_3[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_3$llm_scores), ", ", fixed=T), as.character))
# Experiment 2: Claude-2-chat (rep)
results_4 = read.csv("../claude2-chat-prisma-amstar-rep/results.csv", row.names = 1, na.strings = NULL)
results_4[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_4$llm_scores), ", ", fixed=T), as.character))

# Experiment 5: Claude-2-chat-gpt-prompt
results_claude_amstar_gpt_prompt = read.csv("../claude2-chat-gpt-prompt-amstar/results.csv", row.names = 1, na.strings = NULL)
results_claude_amstar_gpt_prompt[amstar] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_claude_amstar_gpt_prompt$llm_scores), ", ", fixed=T), as.character))
results_claude_prisma_gpt_prompt = read.csv("../claude2-chat-gpt-prompt-prisma/results.csv", row.names = 1, na.strings = NULL)
results_claude_prisma_gpt_prompt[prisma] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_claude_prisma_gpt_prompt$llm_scores), ", ", fixed=T), as.character))
results_5 = cbind(results_claude_amstar_gpt_prompt, results_claude_prisma_gpt_prompt[rownames(results_claude_amstar_gpt_prompt),])

# Experiment 6: Claude-2
results_6 = read.csv("../claude2-prisma-amstar/results.csv", row.names = 1, na.strings = NULL)
results_6[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_6$llm_scores), ", ", fixed=T), as.character))
# Experiment 7: Claude-2 (rep)
results_7 = read.csv("../claude2-prisma-amstar-rep/results.csv", row.names = 1, na.strings = NULL)
results_7[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_7$llm_scores), ", ", fixed=T), as.character))

# Experiment 8: GPT-4
results_8 = read.csv("../gpt4-prisma-amstar/results.csv", row.names = 1, na.strings = NULL)
results_8[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_8$llm_scores), ", ", fixed=T), as.character))
results_8 = results_8[rownames(results_6),]
rownames(results_8) = rownames(results_6)
results_8[is.na(results_8)] = "NA" # because some papers are missing

stopifnot((rownames(results_1) == rownames(results_2)) & (rownames(results_1) == rownames(results_3)) & (rownames(results_1) == rownames(results_4)) & (rownames(results_1) == rownames(results_5)) & (rownames(results_1) == rownames(results_6)) & (rownames(results_1) == rownames(results_7)) & (rownames(results_1) == rownames(results_8)))
stopifnot((items %in% colnames(results_1)) & (items %in% colnames(results_2)) & (items %in% colnames(results_3)) & (items %in% colnames(results_4)) & (items %in% colnames(results_5)) & (items %in% colnames(results_6)) & (items %in% colnames(results_7)) & (items %in% colnames(results_8)))

# Combine results
results = data.frame()
for (row in rownames(results_1)) {
  self_consistency = sapply(items, function(item) table(c(results_1[row, item], results_2[row, item], results_3[row, item], results_4[row, item], results_5[row, item], results_6[row, item], results_7[row, item], results_8[row, item])))
  self_consistency = sapply(self_consistency, function(table) names(which(table >= 6)))
  results[row, items] = ifelse(sapply(self_consistency, length), self_consistency, "deferred")
}

write.csv(results, "results_self_consistency.csv")
