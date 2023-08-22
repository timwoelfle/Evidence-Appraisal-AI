suppressPackageStartupMessages(library(psych)) # cohen.kappa
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(patchwork)) # wrap_plots
suppressPackageStartupMessages(library(jsonlite)) # read_json

# Plot

no_x = theme(axis.title.x=element_blank(), axis.text.x=element_blank(), axis.ticks.x=element_blank())
no_y = theme(axis.title.y=element_blank(), axis.text.y=element_blank(), axis.ticks.y=element_blank())

calc_agreement = function(table_) {
  table_ = table_[rownames(table_) != "deferred", colnames(table_) != "deferred"]
  sum(diag(table_)) / sum(table_)
}

plot_heatmap = function(data, x_rater, y_rater, title, limit_max=NULL) {
  if (is.null(limit_max)) limit_max = max(data$Freq)
  
  if (x_rater == "Human Consensus") data = data[data$x != "deferred",]
  
  ggplot(
    data, 
    aes(x, y)
  ) +
    geom_tile(aes(fill=Freq)) + xlab(x_rater) + ylab(y_rater) +
    geom_abline(slope=1, linewidth=0.3, color="lightgrey") +
    geom_text(aes(label=ifelse(Freq==0,"",Freq))) +
    scale_fill_gradient(low="white", high="red", limits=c(0, limit_max)) +
    ggtitle(title) +
    theme_bw() +
    theme(legend.position="none")
}

plot_metrics_overview = function(results, domains, x_rater, y_rater, factorize, weight_matrix, useNA="no", ncol=3, nrow=3, save_results=T) {
  all_domains_table = table(x=factorize(unlist(results[,paste0(domains, "_", x_rater)])), y=factorize(unlist(results[,paste0(domains, "_", y_rater)])), useNA=useNA)
  
  all_domains_cohen_kappa_w = cohen.kappa(all_domains_table, w=weight_matrix)$weighted.kappa
  all_domains_agreement = calc_agreement(all_domains_table)
  all_domains_deferring_fraction = ifelse("deferred" %in% colnames(all_domains_table), sum(all_domains_table[,"deferred"]) / sum(all_domains_table), 0)
  all_domains_heatmap = plot_heatmap(as.data.frame(all_domains_table), x_rater, y_rater, paste0("All domains (κ=", round(all_domains_cohen_kappa_w, 2), ", a=", round(all_domains_agreement, 2), ")"))
  
  domain_tables = list()
  domain_cohen_kappa_w = c()
  domain_agreement = c()
  domain_deferring_fraction = c()
  domain_heatmaps = list()
  for (domain in domains) {
    domain_tables[[domain]] = table(x=factorize(results[,paste0(domain, "_", x_rater)]), y=factorize(results[,paste0(domain, "_", y_rater)]), useNA=useNA)
    domain_cohen_kappa_w[domain] = cohen.kappa(domain_tables[[domain]], w=weight_matrix)$weighted.kappa
    domain_agreement[domain] = calc_agreement(domain_tables[[domain]])
    domain_deferring_fraction[domain] = ifelse("deferred" %in% colnames(domain_deferring_fraction[domain]), sum(domain_tables[[domain]][,"deferred"]) / sum(domain_tables[[domain]]), 0)
    domain_heatmaps[[domain]] = plot_heatmap(as.data.frame(domain_tables[[domain]]), x_rater, y_rater, paste0(domain, " (κ=", round(domain_cohen_kappa_w[[domain]],2), ", a=", round(domain_agreement[[domain]],2), ")"), max(sapply(domain_tables, max))) + xlab(NULL) + ylab(NULL) + no_x + no_y
  }
  
  if (save_results) {
    filename_prefix = paste0(x_rater, "_", y_rater, "_", length(domains), "_domains_", nrow(weight_matrix), "_options")
    write.csv(
      data.frame(
        cohen_kappa_w=c(all_domains_cohen_kappa_w, domain_cohen_kappa_w), 
        agreement=c(all_domains_agreement, domain_agreement), 
        deferring_fraction=c(all_domains_deferring_fraction, domain_deferring_fraction),
        row.names = c("combined", domains)
      ), 
      paste0("results/", filename_prefix, "_IRR.csv")
    )
  }
  
  all_domains_kappa_vs_agreement = qplot(unlist(domain_cohen_kappa_w), unlist(domain_agreement), xlab="Kappa", ylab="Agreement", xlim=c(-0.2,1), ylim=c(0,1), size=I(3)) + theme_bw()
  
  bar_data = rbind(
    cbind(as.data.frame(table(Score=factorize(unlist(results[,paste0(domains, "_", x_rater)])), useNA = useNA)), Rater="x"),
    cbind(as.data.frame(table(Score=factorize(unlist(results[,paste0(domains, "_", y_rater)])), useNA = useNA)), Rater="y")
  )
  bar_plot = ggplot(bar_data, aes(x=Score, y=Freq, fill=Rater)) +
    geom_bar(stat="identity", position="dodge") + scale_fill_manual(values=c("x"="#2780e3", "y"="#ff9e81")) + theme_bw() + xlab(NULL) + ggtitle(paste0(x_rater, " (blue) vs ", y_rater, " (red)")) + theme(legend.position="none")
  
  for (row in rownames(results)) {
    individual_table = table(factorize(unlist(results[row, paste0(domains, "_", x_rater)])), factorize(unlist(results[row, paste0(domains, "_", y_rater)])), useNA=useNA)
    results[row, "agreement"] = calc_agreement(individual_table)
    results[row, "cohen_kappa"] = ifelse(results[row, "agreement"] == 1, 1, cohen.kappa(individual_table, w=weight_matrix)$weighted.kappa)
  }
  
  individual_publications = qplot(results$cohen_kappa, results$agreement, xlab="Kappa", ylab="Agreement", xlim=c(-0.55,1), ylim=c(0,1), size=I(3), alpha=I(0.8)) + theme_bw() + ggtitle(paste0("Individual publications' ratings (n=", nrow(results), ")"))
  
  plot = wrap_plots(
    wrap_plots(
      bar_plot, 
      wrap_plots(all_domains_heatmap, all_domains_kappa_vs_agreement, ncol=2),
      individual_publications, 
      nrow=3
    ),
    wrap_plots(domain_heatmaps, ncol=ncol, nrow=nrow),
    ncol=2,
    widths=c(0.4,0.6)
  )
  
  if (save_results) {
    png = paste0("results/", filename_prefix, ".png")
    png(png, width=1920, height=1080, res=124)
    print(plot)
    dev.off()
  }
  
  return(plot)
}

# Quotes

quote_accuracy_html_span = function(quote_accuracy) {
  apply(quote_accuracy, 1, function(x) {
    similarity = as.numeric(x["similarity"])
    color = ifelse(x["best_match_source"] == "fulltext", "black", "#2780e3")
    background_color = ifelse(similarity < 75, "red", ifelse(similarity < 95, "#ff9e81", ifelse(similarity < 100, "#ffe9e2", "transparent")))
    if (similarity < 100) title = paste0(ifelse(similarity < 75, "Major quote deviation, possible hallucination. ", ifelse(similarity < 95, "Moderate quote deviation. ", "Minor quote deviation. ")), "Best match in ", x["best_match_source"], " (Similarity ", round(similarity, 1), "%):\n\n", trimws(gsub("'", "&#39;", x["best_match"], fixed=T)))
    else title = paste0("Perfect quote from ", x["best_match_source"], " (Similarity ", round(similarity, 1), "%).")
    
    paste0("<span title='", title, "' style='border-bottom: 1px dashed ", color, "; color: ", color, "; background-color: ", background_color, "'>", insert_invis_char(x["quote"]), "</span>")
  })
}

# Insert this invisible char after the first character of each quote to make sure that it is only replaced with span once
insert_invis_char = function(str) paste0("&quot;‎", str, "&quot;")

cat_llm_response = function(id, wrong_format, llm_message, quotes) {
  cat("<span style='padding: 8px 0; color: #999'>LLM response</span>\n\n")
  wrong_format = gsub("\\[|\\]", "", wrong_format)
  if (wrong_format != "") cat("<i>Minor score formatting issues fixed during extraction: ", wrong_format, "</i>\n\n", sep="")
  
  if (sum(quotes$best_match_source == "fulltext")) cat("<i><span style='border-bottom: 1px dashed black;'>", sum(quotes$best_match_source == "fulltext"), " quote(s) from publication full text</span> (mean similarity ", round(mean(quotes[quotes$best_match_source == "fulltext", "similarity"]), 1), "%)</i>\n\n", sep="")
  if (sum(quotes$best_match_source == "prompt")) cat("<i><span style='border-bottom: 1px dashed #2780e3; color: #2780e3;'>", sum(quotes$best_match_source == "prompt"), " quote(s) from the LLM prompt briefing</span> (mean similarity ", round(mean(quotes[quotes$best_match_source == "prompt", "similarity"]), 1), "%) - were instructions quoted (ok) or examples (unwanted beahviour)?</i>\n\n", sep="")
  
  for (ind in rownames(quotes)) {
    # Replace each quote one after another (i.e. quotes must be ordered in csv), do not use gsub with this strategy
    llm_message = sub(paste0('"', quotes[ind, "quote"], '"'), quotes[ind, "html_span"], llm_message, fixed=T, useBytes = T)
  }
  
  llm_message = gsub("<added>", "<span style='background-color: #ff9e81' title='Added response during extraction'>", llm_message)
  llm_message = gsub("<added-score-prefix>", "<span style='background-color: #ff9e81' title='Added score prefix during extraction'>", llm_message)
  llm_message = gsub("<added-squared-brackets>", "<span style='background-color: #ffe9e2' title='Added squared brackets during extraction'>", llm_message)
  llm_message = gsub("<moved-squared-brackets>", "<span style='background-color: #ffe9e2' title='Moved squared brackets during extraction'>", llm_message)
  llm_message = gsub("</added>|</added-score-prefix>|</added-squared-brackets>|</moved-squared-brackets>", "</span>", llm_message)
  
  
  cat("<pre>\n")
  cat(trimws(llm_message))
  cat("</pre>\n")
}

cat_quote_accuracy = function(results, quote_accuracy) {
  perfect_fulltext_quotes = quote_accuracy[quote_accuracy$best_match_source == "fulltext" & quote_accuracy$similarity==100,]
  perfect_prompt_quotes = quote_accuracy[quote_accuracy$best_match_source == "prompt" & quote_accuracy$similarity==100,]
  
  cat('* ', nrow(quote_accuracy), ' quotes for ', length(unique(quote_accuracy$publication_id)), ' / ', nrow(results), ' (', round(length(unique(quote_accuracy$publication_id)) / nrow(results)*100,1), '%) publications, median ', median(table(quote_accuracy$publication_id)), ' (IQR ', quantile(table(quote_accuracy$publication_id), 0.25), '-', quantile(table(quote_accuracy$publication_id), 0.75), ', range ', min(table(quote_accuracy$publication_id)), '-', max(table(quote_accuracy$publication_id)), ')\n', sep="")
  cat('* ', nrow(perfect_fulltext_quotes), ' / ', nrow(quote_accuracy), ' (', round(nrow(perfect_fulltext_quotes) / nrow(quote_accuracy)*100,1), '%) perfect <span style="border-bottom: 1px dashed black;">quotes from the publication full text</span>\n', sep="")
  cat('* ', nrow(perfect_prompt_quotes), ' / ', nrow(quote_accuracy), ' (', round(nrow(perfect_prompt_quotes) / nrow(quote_accuracy)*100,1), '%) perfect <span style="border-bottom: 1px dashed #2780e3; color: #2780e3;">quotes from the LLM prompt briefing</span> - were instructions quoted (ok) or examples (unwanted beahviour)?\n', sep="")
  cat('* ', sum(quote_accuracy$similarity != 100), ' / ', nrow(quote_accuracy), ' (', round(sum(quote_accuracy$similarity != 100) / nrow(quote_accuracy)*100,1), '%) quotes with deviations from source, where the accuracy was measured by a ["normalized Levenshtein similarity"](https://maxbachmann.github.io/RapidFuzz/Usage/distance/Levenshtein.html#normalized-similarity) <span style="border-bottom: 1px dashed black;" title="Weights for insertion: 1, deletion: 0.5, substitution: 1.5. Penalizes &quot;positive hallucinations&quot; (insertions) more than omissions of e.g. brackets and references (deletions).">with custom weights</span>, ranging from 0-100%\n', sep="")
  cat('  * <span style="background-color: #ffe9e2">', sum(quote_accuracy$similarity < 100 & quote_accuracy$similarity >= 95), ' minor</span> deviations (95% ≤ similarity < 100%); mean: ', round(mean(quote_accuracy[quote_accuracy$similarity < 100 & quote_accuracy$similarity >= 95, "similarity"]),1), '%\n', sep="")
  cat('  * <span style="background-color: #ff9e81">', sum(quote_accuracy$similarity < 95 & quote_accuracy$similarity >= 75), ' moderate</span> deviations (75% ≤ similarity < 95%); mean: ', round(mean(quote_accuracy[quote_accuracy$similarity < 95 & quote_accuracy$similarity >= 75, "similarity"]),1), '%\n', sep="")
  cat('  * <span style="background-color: red">', sum(quote_accuracy$similarity < 75), ' major</span> deviations (similarity < 75%); mean: ', round(mean(quote_accuracy[quote_accuracy$similarity < 75, "similarity"]),1), '%\n', sep="")
  
  df = quote_accuracy[quote_accuracy$similarity < 100, c("publication_id", "best_match_source", "html_span", "similarity")]
  df$publication_id = results[as.character(df$publication_id), "author_year"]
  datatable(
    df, 
    rownames=F, 
    colnames=c("Author & Year", "Source", "Quote with deviation", "Similarity"), 
    escape=F, 
    fillContainer=F,
    options=list(bPaginate=F, dom="ft", order=list(list(3, "desc")), columnDefs=list(list(visible=F, targets=1)))
  ) %>% formatRound(4, digits=1)
}

# Formatting accuracy

cat_formatting_accuracy = function(results, human) {
  # Wrong response format that was fixed during score extraction
  results$wrong_format = gsub("\\[|\\'|\\]| ", "", results$wrong_format)
  wrong_format = strsplit(results$wrong_format, ",")
  n_wrong_format = table(sapply(wrong_format, length))
  wrong_format_table = sort(table(unlist(wrong_format)), decreasing = T)
  
  # Failed responses that had to be repeated
  failed_responses_paths = list.files("responses/failed_responses", full.names = T)
  failed_responses_paths = failed_responses_paths[grepl(".txt|.json", failed_responses_paths)]
  failed_responses = data.frame()
  for (path in failed_responses_paths) {
    if (grepl(".json", path)) llm_message = read_json(path)$choices[[1]]$message$content
    else llm_message = readChar(path, file.info(path)$size)
    failed_responses = rbind(failed_responses, list(
      id = strsplit(gsub(".*\\/", "", path), "\\.")[[1]][1],
      reason = strsplit(gsub(".*\\/", "", path), "\\.")[[1]][2],
      llm_message = llm_message
    ))
  }
  failed_responses = failed_responses[order(as.integer(failed_responses$id)),]
  failed_responses$author_year = human[failed_responses$id, "author_year"]
  failed_responses$ultimately_successful = failed_responses$id %in% rownames(results)
  failed_responses$llm_message = gsub('"', "'", failed_responses$llm_message, fixed=T)
  for (id in rownames(results)) {
    results[id, "n_retries"] = sum(failed_responses$id == id)
  }
  no_results = as.character(unique(failed_responses[!failed_responses$ultimately_successful, "id"]))
  
  # Output
  cat("  * ", n_wrong_format["0"], " / ", nrow(results), " (", round(n_wrong_format["0"]/nrow(results)*100, 1), "%) usable responses with correctly formatted scores\n", sep="")
  cat("  * ", nrow(results)-n_wrong_format["0"], " / ", nrow(results), " (", round((nrow(results)-n_wrong_format["0"])/nrow(results)*100, 1), "%) usable responses with minor fixable score formatting issues\n", sep="")
  for (x in names(wrong_format_table)) {
    cat  ("    * ", wrong_format_table[x], " with '", x, "'\n", sep="")
  }
  cat("<br><br>\n")
  
  cat("* ", sum(results$n_retries == 0), " / ", nrow(human), " (", round(sum(results$n_retries==0)/nrow(human)*100, 1), "%) publications yielded usable responses in the first try\n", sep="")
  cat("* ", sum(results$n_retries > 0), " / ", nrow(human), " (", round(sum(results$n_retries>0)/nrow(human)*100, 1), "%) publications yielded usable responses after a median of ", median(results[results$n_retries>0, "n_retries"]), " retries  (IQR ", quantile(results[results$n_retries>0, "n_retries"], 0.25), "-", quantile(results[results$n_retries>0, "n_retries"], 0.75), ", range ", min(results[results$n_retries>0, "n_retries"]), "-", max(results[results$n_retries>0, "n_retries"]), "), thus being ultimately successful\n", sep="")
  failed_response_reasons_table = sort(table(unlist(failed_responses[failed_responses$ultimately_successful, "reason"])), decreasing = T)
  for (x in names(failed_response_reasons_table)) {
    cat  ("  * ", failed_response_reasons_table[x], " responses with failure reason '", x, "'\n", sep="")
  }
  cat("* ", length(no_results), " / ", nrow(human), " (", round(length(no_results)/nrow(human)*100, 1), "%) publications yielded no usable responses and were thus ultimately unsuccessful. ", paste0(paste0("[", human[no_results, "author_year"], "](https://doi.org/", human[no_results, "DOI"], ")"), collapse=", "), "\n", sep="")
  failed_response_reasons_table = sort(table(unlist(failed_responses[!failed_responses$ultimately_successful, "reason"])), decreasing = T)
  for (x in names(failed_response_reasons_table)) {
    cat  ("  * ", failed_response_reasons_table[x], " responses with failure reason '", x, "'\n", sep="")
  }
  
  if (nrow(failed_responses)) {
    cell_tooltip_js = function(col_id) paste0("function(data, type, row, meta) { return '<a onclick=\"javascript:alert(`'+row[", col_id, "]+'`)\" style=\"cursor: pointer\">' + data + '</a>' }")
    datatable(
      failed_responses[c("author_year", "reason", "ultimately_successful", "llm_message")], 
      colnames=c("Author & Year", "Reason for failed response (click to show LLM response)", "Ultimately successful", "LLM response"), 
      rownames = T, escape=T, fillContainer=F, 
      options=list(bPaginate=F, dom="ft", columnDefs=list(list(targets=2, render=JS(cell_tooltip_js(4))), list(targets=c(0,4), visible=F)))
    )
  }
}
