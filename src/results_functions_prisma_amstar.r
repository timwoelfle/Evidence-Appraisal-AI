suppressPackageStartupMessages(library(psych)) # cohen.kappa
suppressPackageStartupMessages(library(DT)) # datatable

prisma = paste0("P", 1:27)
amstar = paste0("A", 1:11)

factorize = function(x) factor(x, levels=c("0","1","NA"))
weight_matrix=matrix(c(0,1,1,1,0,1,1,1,0),nrow=3)

datatable_scores = function(results, x_rater, y_rater, factorize, weigth_matrix, useNA="ifany") {
  show_prisma = all(paste0(prisma, "_", x_rater) %in% colnames(results))
  show_amstar = all(paste0(amstar, "_", x_rater) %in% colnames(results))
  
  # Individual publications' ratings
  for (row in rownames(results)) {
    if (show_prisma) {
      prisma_table = table(factorize(unlist(results[row, paste0(prisma, "_", x_rater)])), factorize(unlist(results[row, paste0(prisma, "_", y_rater)])), useNA=useNA)
      results[row, "prisma_agreement"] = calc_agreement(prisma_table)
      results[row, "prisma_cohen_kappa"] = ifelse(results[row, "prisma_agreement"] == 1, 1, cohen.kappa(prisma_table, w=weight_matrix)$weighted.kappa)
    }
    if (show_amstar) {
      amstar_table = table(factorize(unlist(results[row, paste0(amstar, "_", x_rater)])), factorize(unlist(results[row, paste0(amstar, "_", y_rater)])), useNA=useNA)
      results[row, "amstar_agreement"] = calc_agreement(amstar_table)
      results[row, "amstar_cohen_kappa"] = ifelse(results[row, "amstar_agreement"] == 1, 1, cohen.kappa(amstar_table, w=weight_matrix)$weighted.kappa)
    }
  }
  
  results$Reference = rownames(results)
  results$title_link = paste0("<a href='#", rownames(results), "' title='Jump to individual results on the right'>", results$title, "</a>")
  
  columns = c("Reference", "title_link")
  colnames = c("Ref.", "Author & Year")
  if (show_prisma) {
    columns = c(columns, "prisma_cohen_kappa", "prisma_agreement")
    colnames = c(colnames, "PRISMA κ", "PRISMA agreement")
  }
  if (show_amstar) {
    columns = c(columns, "amstar_cohen_kappa", "amstar_agreement")
    colnames = c(colnames, "AMSTAR κ", "AMSTAR agreement")
  }
  
  datatable(
    results[columns],
    colnames=colnames,
    rownames=F,
    escape=F, 
    options=list(bPaginate=F, dom="t", order=list(list(0, "asc")))
  ) %>% formatRound(3:length(columns))
}

cat_individual_results = function(results, x_rater, y_rater, domain_instructions, quote_accuracy, show_llm_message=T) {
  show_prisma = all(paste0(prisma, "_", x_rater) %in% colnames(results))
  show_amstar = all(paste0(amstar, "_", x_rater) %in% colnames(results))
  
  results[results == "deferred"] = "def."
  
  for (id in rownames(results)) {
    cat("<a name='", id, "'></a>\n\n", sep="")
    cat("#### <a href='", results[id, "link"], "' title='Open publication'>", results[id, "title"], "</a>\n\n", sep="")
    
    if (show_prisma) {
      rownames = paste0("<span style='border-bottom: 1px dashed black' title='", gsub("'", "&#39;", domain_instructions[paste0(prisma, ".")]), "'> ", prisma, "</span>")
      cat(knitr::kable(data.frame(t(data.frame(unlist(results[id, paste0(prisma[1:14], "_", x_rater)]), unlist(results[id, paste0(prisma[1:14], "_", y_rater)]), row.names = rownames[1:14])), row.names=c(x_rater, y_rater), check.names = F), format="html", escape=F, table.attr="style='margin: 0; width: 100%'", caption="PRISMA"), "\n\n")
      cat(knitr::kable(data.frame(t(data.frame(unlist(results[id, paste0(prisma[15:27], "_", x_rater)]), unlist(results[id, paste0(prisma[15:27], "_", y_rater)]), row.names = rownames[15:27])), row.names=c(x_rater, y_rater), check.names = F), format="html", escape=F, table.attr="style='margin: 0; width: 100%; border-top: 0'"), "<br>")
    }
    
    if (show_amstar) {
      rownames = paste0("<span style='border-bottom: 1px dashed black' title='", gsub("'", "&#39;", domain_instructions[paste0("A", 1:11, ".")]), "'> A", 1:11, "</span>")
      cat(knitr::kable(data.frame(t(data.frame(unlist(results[id, paste0(amstar, "_", x_rater)]), unlist(results[id, paste0(amstar, "_", y_rater)]), row.names = rownames)), row.names=c(x_rater, y_rater), check.names = F), format="html", escape=F, table.attr="style='margin: 0; width: 100%'", caption="AMSTAR"), "<br>")
    }
    
    if (show_llm_message) {
      cat_llm_response(id, results[id, "wrong_format"], results[id, "llm_message"], quote_accuracy[quote_accuracy$publication_id == id,])
    }
  }
}
