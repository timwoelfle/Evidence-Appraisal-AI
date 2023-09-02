source("../../../src/results_functions_prisma_amstar.r") # prisma, amstar

items = c(amstar, prisma)

# Experiment 1: Claude
results_1 = read.csv("../claude2_prisma-amstar/results.csv", row.names = 1, na.strings = NULL)
results_1[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_1$llm_scores), ", ", fixed=T), as.character))
# Experiment 2: Claude (rep)
results_2 = read.csv("../claude2_prisma-amstar_rep/results.csv", row.names = 1, na.strings = NULL)
results_2[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_2$llm_scores), ", ", fixed=T), as.character))
# Experiment 3: GPT
results_gpt_amstar_1 = read.csv("../gpt3.5_amstar/results.csv", row.names = 1, na.strings = NULL)
results_gpt_amstar_1[amstar] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt_amstar_1$llm_scores), ", ", fixed=T), as.character))
results_gpt_prisma_1 = read.csv("../gpt3.5_prisma/results.csv", row.names = 1, na.strings = NULL)
results_gpt_prisma_1[prisma] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt_prisma_1$llm_scores), ", ", fixed=T), as.character))
results_3 = cbind(results_gpt_amstar_1, results_gpt_prisma_1[rownames(results_gpt_amstar_1),])
results_3[is.na(results_3)] = "NA" # because some papers are missing in results_gpt_prisma_1

# Experiment 4: GPT (rep)
results_gpt_amstar_2 = read.csv("../gpt3.5_amstar_rep/results.csv", row.names = 1, na.strings = NULL)
results_gpt_amstar_2[amstar] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt_amstar_2$llm_scores), ", ", fixed=T), as.character))
results_gpt_prisma_2 = read.csv("../gpt3.5_prisma_rep/results.csv", row.names = 1, na.strings = NULL)
results_gpt_prisma_2[prisma] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_gpt_prisma_2$llm_scores), ", ", fixed=T), as.character))
results_4 = cbind(results_gpt_amstar_2, results_gpt_prisma_2[rownames(results_gpt_amstar_2),])
results_4[is.na(results_4)] = "NA" # because some papers are missing in results_gpt_prisma_2

# Experiment 5: Claude (GPT-prompt)
results_claude_amstar_gpt_prompt = read.csv("../claude2_amstar-gpt-prompt/results.csv", row.names = 1, na.strings = NULL)
results_claude_amstar_gpt_prompt[amstar] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_claude_amstar_gpt_prompt$llm_scores), ", ", fixed=T), as.character))
results_claude_prisma_gpt_prompt = read.csv("../claude2_prisma-gpt-prompt/results.csv", row.names = 1, na.strings = NULL)
results_claude_prisma_gpt_prompt[prisma] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results_claude_prisma_gpt_prompt$llm_scores), ", ", fixed=T), as.character))
results_5 = cbind(results_claude_amstar_gpt_prompt, results_claude_prisma_gpt_prompt[rownames(results_claude_amstar_gpt_prompt),])

stopifnot((rownames(results_1) == rownames(results_2)) & (rownames(results_1) == rownames(results_3)) & (rownames(results_1) == rownames(results_4)) & (rownames(results_1) == rownames(results_5)))
stopifnot((items %in% colnames(results_1)) & (items %in% colnames(results_2)) & (items %in% colnames(results_3)) & (items %in% colnames(results_4)) & (items %in% colnames(results_5)))

# Combine results
results = data.frame()
for (row in rownames(results_1)) {
  self_consistency = sapply(items, function(item) table(c(results_1[row, item], results_2[row, item], results_3[row, item], results_4[row, item], results_5[row, item])))
  self_consistency = sapply(self_consistency, function(table) names(which(table >= 5)))
  results[row, items] = ifelse(sapply(self_consistency, length), self_consistency, "deferred")
}

write.csv(results, "results_self_consistency.csv")
