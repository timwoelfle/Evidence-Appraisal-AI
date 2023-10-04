suppressPackageStartupMessages(library(psych)) # cohen.kappa
suppressPackageStartupMessages(library(boot))
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

get_kappa_agreement_deferring = function(results, indices, items, x_rater, y_rater, factorize, weight_matrix, useNA) {
  items_table = table(x=factorize(unlist(results[indices, paste0(items, "_", x_rater)])), y=factorize(unlist(results[indices, paste0(items, "_", y_rater)])), useNA=useNA)
  
  return(c(
    cohen_kappa_w = cohen.kappa(items_table, w=weight_matrix)$weighted.kappa,
    agreement = calc_agreement(items_table),
    deferring_fraction = sum(items_table["deferred",]) / sum(items_table)
  ))
}

plot_heatmap = function(data, x_rater, y_rater, title, limit_max=NULL) {
  if (is.null(limit_max)) limit_max = max(data$Freq)
  
  if (!sum(data[data$x == "deferred", "Freq"])) data = data[data$x != "deferred",]
  if (!sum(data[data$y == "deferred", "Freq"])) data = data[data$y != "deferred",]
  
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

plot_metrics_overview = function(results, items, x_rater, y_rater, factorize, weight_matrix, useNA="no", save_results=T, filename_prefix="human_consensus") {
  ncol=3
  nrow=3
  if (length(items) > 9) nrow = 4
  if (length(items) > 11) {
    ncol = 5
    nrow = 6
  }
  
  boot_all_items = boot(results, get_kappa_agreement_deferring, 1000, items=items, x_rater=x_rater, y_rater=y_rater, factorize=factorize, weight_matrix=weight_matrix, useNA=useNA)
  all_items_table = table(x=factorize(unlist(results[,paste0(items, "_", x_rater)])), y=factorize(unlist(results[,paste0(items, "_", y_rater)])), useNA=useNA)
  all_items_cohen_kappa_w = boot_all_items$t0["cohen_kappa_w"]
  all_items_agreement = boot_all_items$t0["agreement"]
  all_items_deferring_fraction = boot_all_items$t0["deferring_fraction"]
  
  all_items_heatmap = plot_heatmap(as.data.frame(all_items_table), x_rater, y_rater, paste0("Overall (κ=", round(all_items_cohen_kappa_w, 2), ", a=", round(all_items_agreement, 2), ifelse(all_items_deferring_fraction, paste0(", def.=", round(all_items_deferring_fraction, 2)), ""), ")"))
  
  item_tables = list()
  item_cohen_kappa_w = c()
  item_agreement = c()
  item_deferring_fraction = c()
  item_heatmaps = list()
  for (i in seq_len(length(items))) {
    item = items[[i]]
    item_tables[[item]] = table(x=factorize(results[,paste0(item, "_", x_rater)]), y=factorize(results[,paste0(item, "_", y_rater)]), useNA=useNA)
    item_agreement[item] = calc_agreement(item_tables[[item]])
    item_cohen_kappa_w[item] = ifelse(is.nan(item_agreement[item]), NaN, cohen.kappa(item_tables[[item]], w=weight_matrix)$weighted.kappa)
    item_deferring_fraction[item] = sum(item_tables[[item]]["deferred",]) / sum(item_tables[[item]])
    bracket_string = paste0(" (κ=", round(item_cohen_kappa_w[[item]],2), ", a=", round(item_agreement[[item]],2), ")")
    if (length(names(items))) title = paste0(item, bracket_string, "\n", names(items)[i])
    else title = paste0(item, bracket_string)
    item_heatmaps[[item]] = plot_heatmap(as.data.frame(item_tables[[item]]), x_rater, y_rater, title, max(sapply(item_tables, max))) + xlab(NULL) + ylab(NULL) + no_x + no_y
  }
  
  if (save_results) {
    dir.create("results", showWarnings = F)
    filename = paste0(filename_prefix, "_", length(items), "_items")
    #write.csv(all_items_table, paste0("results/", filename, "_all_items_table.csv"))
    write.csv(
      data.frame(
        cohen_kappa_w=c(all_items_cohen_kappa_w, item_cohen_kappa_w),
        cohen_kappa_w_ci_low=c(boot.ci(boot_all_items, type="perc", index=1)$percent[4], rep(NA, length(items))),
        cohen_kappa_w_ci_high=c(boot.ci(boot_all_items, type="perc", index=1)$percent[5], rep(NA, length(items))),
        agreement=c(all_items_agreement, item_agreement),
        agreement_ci_low=c(boot.ci(boot_all_items, type="perc", index=2)$percent[4], rep(NA, length(items))),
        agreement_ci_high=c(boot.ci(boot_all_items, type="perc", index=2)$percent[5], rep(NA, length(items))),
        deferring_fraction=c(all_items_deferring_fraction, item_deferring_fraction),
        deferring_fraction_ci_low=c(boot.ci(boot_all_items, type="perc", index=3)$percent[4], rep(NA, length(items))),
        deferring_fraction_ci_high=c(boot.ci(boot_all_items, type="perc", index=3)$percent[5], rep(NA, length(items))),
        row.names = c("combined", items)
      ), 
      paste0("results/", filename, ".csv")
    )
  }
  
  all_items_kappa_vs_agreement = qplot(unlist(item_cohen_kappa_w), unlist(item_agreement), xlab="Kappa", ylab="Agreement", xlim=c(-0.2,1), ylim=c(0,1), size=I(3)) + ggtitle(paste0("Individual items (n=", length(items), ")")) + theme_bw()
  
  bar_data = rbind(
    cbind(as.data.frame(table(Score=factorize(unlist(results[,paste0(items, "_", x_rater)])), useNA = useNA)), Rater="x"),
    cbind(as.data.frame(table(Score=factorize(unlist(results[,paste0(items, "_", y_rater)])), useNA = useNA)), Rater="y")
  )
  if (!sum(bar_data[bar_data$Score == "deferred", "Freq"])) bar_data = bar_data[bar_data$Score != "deferred",]
  bar_plot = ggplot(bar_data, aes(x=Score, y=Freq, fill=Rater)) +
    geom_bar(stat="identity", position="dodge") + scale_fill_manual(values=c("x"="#2780e3", "y"="#ff9e81")) + theme_bw() + xlab(NULL) + ggtitle(paste0(x_rater, " (blue) vs ", y_rater, " (red)")) + theme(legend.position="none")
  
  for (row in rownames(results)) {
    individual_table = table(factorize(unlist(results[row, paste0(items, "_", x_rater)])), factorize(unlist(results[row, paste0(items, "_", y_rater)])), useNA=useNA)
    results[row, "agreement"] = calc_agreement(individual_table)
    results[row, "cohen_kappa"] = ifelse(results[row, "agreement"] == 1, 1, cohen.kappa(individual_table, w=weight_matrix)$weighted.kappa)
  }
  
  individual_publications = qplot(results$cohen_kappa, results$agreement, xlab="Kappa", ylab="Agreement", xlim=c(-0.55,1), ylim=c(0,1), size=I(3), alpha=I(0.8)) + theme_bw() + ggtitle(paste0("Individual publications' ratings (n=", nrow(results), ")"))
  
  plot = wrap_plots(
    wrap_plots(
      bar_plot, 
      wrap_plots(all_items_heatmap, all_items_kappa_vs_agreement, ncol=2),
      individual_publications, 
      nrow=3
    ),
    wrap_plots(item_heatmaps, ncol=ncol, nrow=nrow),
    ncol=2,
    widths=c(0.4,0.6)
  )
  
  if (save_results) {
    png = paste0("results/", filename, ".png")
    png(png, width=1920, height=1080, res=110)
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
    
    paste0("<span title='", title, "' style='border-bottom: 1px dashed ", color, "; color: ", color, "; background-color: ", background_color, "'>&quot;", x["quote"], "&quot;</span>")
  })
}

cat_llm_response = function(id, wrong_format, llm_message, quotes) {
  cat("<span style='padding: 8px 0; color: #999'>LLM response</span>\n\n")
  wrong_format = gsub("\\[|\\]", "", wrong_format)
  if (wrong_format != "") cat("<i>Minor score formatting issues fixed during extraction: ", wrong_format, "</i>\n\n", sep="")
  
  if (sum(quotes$best_match_source == "fulltext")) cat("<i><span style='border-bottom: 1px dashed black;'>", sum(quotes$best_match_source == "fulltext"), " quote(s) from publication full text</span> (mean similarity ", round(mean(quotes[quotes$best_match_source == "fulltext", "similarity"]), 1), "%)</i>\n\n", sep="")
  if (sum(quotes$best_match_source == "prompt")) cat("<i><span style='border-bottom: 1px dashed #2780e3; color: #2780e3;'>", sum(quotes$best_match_source == "prompt"), " quote(s) from the LLM prompt briefing</span> (mean similarity ", round(mean(quotes[quotes$best_match_source == "prompt", "similarity"]), 1), "%) - were instructions quoted (ok) or examples (unwanted beahviour)?</i>\n\n", sep="")
  
  for (ind in rownames(quotes)) {
    # Replace each quote one after another (i.e. quotes must be ordered in csv), do not use gsub with this strategy
    llm_message = gsub(paste0('"', quotes[ind, "quote"], '"'), quotes[ind, "html_span"], llm_message, fixed=T, useBytes = T)
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

cat_quote_accuracy = function(results, quote_accuracy, add_to_csv=F) {
  for (tool in unique(quote_accuracy$tool)) {
    if (length(unique(quote_accuracy$tool)) > 1) cat("#### ", tool, "\n\n", sep="")
    quote_accuracy_tool = quote_accuracy[quote_accuracy$tool == tool,]
    perfect_fulltext_quotes = quote_accuracy_tool[quote_accuracy_tool$best_match_source == "fulltext" & quote_accuracy_tool$similarity==100,]
    perfect_prompt_quotes = quote_accuracy_tool[quote_accuracy_tool$best_match_source == "prompt" & quote_accuracy_tool$similarity==100,]
    
    cat('* ', nrow(quote_accuracy_tool), ' quotes for ', length(unique(quote_accuracy_tool$publication_id)), ' / ', nrow(results), ' (', round(length(unique(quote_accuracy_tool$publication_id)) / nrow(results)*100,1), '%) publications, median ', median(table(quote_accuracy_tool$publication_id)), ' (IQR ', quantile(table(quote_accuracy_tool$publication_id), 0.25), '-', quantile(table(quote_accuracy_tool$publication_id), 0.75), ', range ', min(table(quote_accuracy_tool$publication_id)), '-', max(table(quote_accuracy_tool$publication_id)), ')\n', sep="")
    cat('* ', nrow(perfect_fulltext_quotes), ' / ', nrow(quote_accuracy_tool), ' (', round(nrow(perfect_fulltext_quotes) / nrow(quote_accuracy_tool)*100,1), '%) perfect <span style="border-bottom: 1px dashed black;">quotes from the publication full text</span>\n', sep="")
    cat('* ', nrow(perfect_prompt_quotes), ' / ', nrow(quote_accuracy_tool), ' (', round(nrow(perfect_prompt_quotes) / nrow(quote_accuracy_tool)*100,1), '%) perfect <span style="border-bottom: 1px dashed #2780e3; color: #2780e3;">quotes from the LLM prompt briefing</span> - were instructions quoted (ok) or examples (unwanted beahviour)?\n', sep="")
    cat('* ', sum(quote_accuracy_tool$similarity != 100), ' / ', nrow(quote_accuracy_tool), ' (', round(sum(quote_accuracy_tool$similarity != 100) / nrow(quote_accuracy_tool)*100,1), '%) quotes with deviations from source, where the accuracy was measured by a ["normalized Levenshtein similarity"](https://maxbachmann.github.io/RapidFuzz/Usage/distance/Levenshtein.html#normalized-similarity) <span style="border-bottom: 1px dashed black;" title="Weights for insertion: 1, deletion: 0.5, substitution: 1.5. Penalizes &quot;positive hallucinations&quot; (insertions) more than omissions of e.g. brackets and references (deletions).">with custom weights</span>, ranging from 0-100%\n', sep="")
    cat('  * <span style="background-color: #ffe9e2">', sum(quote_accuracy_tool$similarity < 100 & quote_accuracy_tool$similarity >= 95), ' minor</span> deviations (95% ≤ similarity < 100%); mean: ', round(mean(quote_accuracy_tool[quote_accuracy_tool$similarity < 100 & quote_accuracy_tool$similarity >= 95, "similarity"]),1), '%\n', sep="")
    cat('  * <span style="background-color: #ff9e81">', sum(quote_accuracy_tool$similarity < 95 & quote_accuracy_tool$similarity >= 75), ' moderate</span> deviations (75% ≤ similarity < 95%); mean: ', round(mean(quote_accuracy_tool[quote_accuracy_tool$similarity < 95 & quote_accuracy_tool$similarity >= 75, "similarity"]),1), '%\n', sep="")
    cat('  * <span style="background-color: red">', sum(quote_accuracy_tool$similarity < 75), ' major</span> deviations (similarity < 75%); mean: ', round(mean(quote_accuracy_tool[quote_accuracy_tool$similarity < 75, "similarity"]),1), '%\n\n', sep="")
    
    if (is.character(add_to_csv)) {
      to_save = data.frame(
        run_folder = add_to_csv,
        tool = tool,
        total_results_n = nrow(results),
        results_with_quotes_n = length(unique(quote_accuracy_tool$publication_id)),
        quotes_n = nrow(quote_accuracy_tool),
        perfect_fulltext_quotes_n = nrow(perfect_fulltext_quotes),
        perfect_prompt_quotes_n = nrow(perfect_prompt_quotes),
        minor_deviations_n = sum(quote_accuracy_tool$similarity < 100 & quote_accuracy_tool$similarity >= 95),
        moderate_deviations_n = sum(quote_accuracy_tool$similarity < 95 & quote_accuracy_tool$similarity >= 75),
        major_deviations_n = sum(quote_accuracy_tool$similarity < 75)
      )
      if (file.exists("../quoting_accuracy.csv")) to_save = rbind(read.csv("../quoting_accuracy.csv"), to_save)
      write.csv(to_save, "../quoting_accuracy.csv", row.names = F)
    }
  }
  
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

cat_formatting_accuracy = function(results, human, add_to_csv=F) {
  # Wrong response format that was fixed during score extraction
  # Wrong_format is in JSON-format, just remove "['] " characters and it becomes a  comma-separated list
  results$wrong_format = gsub("\\[|\\'|\\]| ", "", results$wrong_format)
  wrong_format = strsplit(results$wrong_format, ",")
  n_wrong_format = table(sapply(wrong_format, length))
  wrong_format_table = sort(table(unlist(wrong_format)), decreasing = T)
  
  # Failed responses that had to be repeated
  failed_responses_paths = list.files("responses/failed_responses", full.names = T)
  failed_responses_paths = failed_responses_paths[grepl(".txt|.json", failed_responses_paths)]
  failed_responses = data.frame()
  for (path in failed_responses_paths) {
    if (grepl(".json", path) & file.info(path)$size) llm_message = read_json(path)$choices[[1]]$message$content
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
  cat("* ", sum(results$n_retries > 0), " / ", nrow(human), " (", round(sum(results$n_retries>0)/nrow(human)*100, 1), "%) publications ultimately yielded usable responses after a median of ", median(results[results$n_retries>0, "n_retries"]), " retries  ", ifelse(sum(results$n_retries > 0), paste0("(IQR ", quantile(results[results$n_retries>0, "n_retries"], 0.25), "-", quantile(results[results$n_retries>0, "n_retries"], 0.75), ", range ", min(results[results$n_retries>0, "n_retries"]), "-", max(results[results$n_retries>0, "n_retries"]), ")"), ""), "\n", sep="")
  failed_response_reasons_table = sort(table(unlist(failed_responses[failed_responses$ultimately_successful, "reason"])), decreasing = T)
  for (x in names(failed_response_reasons_table)) {
    cat  ("  * ", failed_response_reasons_table[x], " responses with failure reason '", x, "'\n", sep="")
  }
  cat("* ", length(no_results), " / ", nrow(human), " (", round(length(no_results)/nrow(human)*100, 1), "%) publications yielded no usable responses and were thus ultimately unsuccessful. ", paste0(paste0("[", human[no_results, "author_year"], "](https://doi.org/", human[no_results, "DOI"], ")"), collapse=", "), "\n", sep="")
  no_results_reasons_table = sort(table(unlist(failed_responses[!failed_responses$ultimately_successful, "reason"])), decreasing = T)
  for (x in names(no_results_reasons_table)) {
    cat  ("  * ", no_results_reasons_table[x], " responses with failure reason '", x, "'\n", sep="")
  }
  
  if (is.character(add_to_csv)) {
    to_save = data.frame(
      run_folder = add_to_csv,
      dataset_n = nrow(human),
      no_results_n = length(no_results),
      no_results = paste(names(no_results_reasons_table), collapse = ", "),
      required_retries_n = sum(results$n_retries > 0),
      required_retries = paste(names(failed_response_reasons_table), collapse = ", "),
      minor_formatting_issues_n = nrow(results)-n_wrong_format["0"],
      minor_formatting_issues = paste(names(wrong_format_table), collapse = ", ")
    )
    if (file.exists("../formatting_accuracy.csv")) to_save = rbind(read.csv("../formatting_accuracy.csv"), to_save)
    write.csv(to_save, "../formatting_accuracy.csv", row.names = F)
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
