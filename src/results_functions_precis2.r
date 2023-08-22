suppressPackageStartupMessages(library(psych)) # cohen.kappa
suppressPackageStartupMessages(library(DT)) # datatable

domains = c("Eligibility", "Recruitment", "Setting", "Organization", "Flex. delivery", "Flex. adherence", "Follow-up", "Outcome", "Analysis")
domains_long = c("Eligibility", "Recruitment", "Setting", "Organization", "Flexibility (delivery)", "Flexibility (adherence)", "Follow-up", "Primary outcome", "Primary analysis")

factorize = function(x) factor(x, levels=c(1,2,3,4,5,"NA"))
factorize_pooled = function(x) factor(x, levels=c(1,2,3,4,5,"NA"), labels=c("1/2", "1/2", "3", "4/5", "4/5", "NA"))
# Weight matrix: (NA vs any score is weighted 4)
#      [,1] [,2] [,3] [,4] [,5] [,NA]
# [1,]    0    1    4    9   16    4
# [2,]    1    0    1    4    9    4
# [3,]    4    1    0    1    4    4
# [4,]    9    4    1    0    1    4
# [5,]   16    9    4    1    0    4
# [NA,]   4    4    4    4    4    0
weight_matrix = matrix(c(0,1,4,9,16,4, 1,0,1,4,9,4, 4,1,0,1,4,4, 9,4,1,0,1,4, 16,9,4,1,0,4, 4,4,4,4,4,0), nrow=6)
weight_matrix_pooled = matrix(c(0,1,4,1, 1,0,1,1, 4,1,0,1, 1,1,1,0), nrow=4)

# Unpure function: uses factorize/factorize_pooled and weight_matrix/weight_matrix_pooled defined above
datatable_scores = function(results, x_rater, y_rater, useNA="no") {
  # Individual publications' ratings
  for (row in rownames(results)) {
    row_table = table(factorize(unlist(results[row, paste0(domains, "_", x_rater)])), factorize(unlist(results[row, paste0(domains, "_", y_rater)])), useNA=useNA)
    results[row, "agreement"] = calc_agreement(row_table)
    results[row, "cohen_kappa_w"] = ifelse(results[row, "agreement"] == 1, 1, cohen.kappa(row_table, w=weight_matrix)$weighted.kappa)
    row_table_pooled = table(factorize_pooled(unlist(results[row, paste0(domains, "_", x_rater)])), factorize_pooled(unlist(results[row, paste0(domains, "_", y_rater)])), useNA=useNA)
    results[row, "pooled_agreement"] = calc_agreement(row_table_pooled)
    results[row, "pooled_cohen_kappa_w"] = ifelse(results[row, "pooled_agreement"] == 1, 1, cohen.kappa(row_table_pooled, w=weight_matrix_pooled)$weighted.kappa)
  }
  
  results$Reference = rownames(results)
  results$author_year_link = paste0("<a href='#", rownames(results), "' title='Jump to individual results on the right'>", results$author_year, "</a>")
  
  columns = c("Reference", "author_year_link", "cohen_kappa_w", "agreement", "pooled_cohen_kappa_w", "pooled_agreement")
  colnames = c("Ref.", "Author & Year", "weighted κ", "agreement", "pooled weighted κ", "pooled agreement")
  
  datatable(
    results[columns],
    colnames=colnames,
    rownames=F,
    escape=F, 
    options=list(bPaginate=F, dom="t", order=list(list(0, "asc")))
  ) %>% formatRound(3:length(columns))
}

# Unpure function: uses domains defined above
cat_individual_results = function(results, x_rater, y_rater, domain_instructions, quote_accuracy, show_llm_message=T) {
  results[results == "deferred"] = "def."
  
  for (id in rownames(results)) {
    cat("<a name='", id, "'></a>\n\n", sep="")
    cat("#### ", id, ". <a href='", results[id, "link"], "' title='Open publication'>", results[id, "author_year"], ": <i>", results[id, "title"], "</i></a>\n\n", sep="")
    
    rownames = paste0("<span style='border-bottom: 1px dashed black' title='", domain_instructions, "'> ", paste0("D", 1:9), "</span>")
    cat(knitr::kable(data.frame(t(data.frame(unlist(results[id, paste0(domains, "_", x_rater)]), unlist(results[id, paste0(domains, "_", y_rater)]), row.names = rownames)), row.names=c(x_rater, y_rater), check.names = F), format="html", escape=F, table.attr="style='margin: 0; width: 100%'", caption="PRECIS-2"), "<br>")
    
    if (show_llm_message) {
      cat_llm_response(id, results[id, "wrong_format"], results[id, "llm_message"], quote_accuracy[quote_accuracy$publication_id == id,])
    }
  }
}