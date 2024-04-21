suppressPackageStartupMessages(library(psych)) # cohen.kappa
suppressPackageStartupMessages(library(DT)) # datatable

prisma = c(
  "Title"="P1", "Abstract"="P2",
  "I: Rationale"="P3", "I: Objectives"="P4", 
  "M: Protocol"="P5", "M: Eligiblity"="P6", "M: Sources"="P7", "M: Search"="P8", "M: Selection"="P9", "M: Data Collection"="P10", "M: Data Items"="P11", "M: Risk of Bias"="P12", "M: Summary Measures"="P13", "M: Synthesis"="P14", "M: Publication Bias"="P15", "M: Additional Analyses"="P16", 
  "R: Selection"="P17", "R: Characteristics"="P18", "R: Risk of Bias"="P19", "R: Individual Results"="P20", "R: Synthesis"="P21", "R: Publication Bias"="P22", "R: Additional Analyses"="P23",
  "D: Summary"="P24", "D: Limitations"="P25", "D: Conclusions"="P26", "Funding"="P27"
)
amstar = c(
  "A Priori Design"="A1", "Selection / Extraction"="A2", "Search"="A3", "Publication Status"="A4", "List of Studies"="A5", "Characteristics"="A6", "Quality Assessed"="A7", "Quality Considered"="A8", "Appropriate Methods"="A9", "Publication Bias"="A10", "Conflicts of Interests"="A11"
)

item_instructions = c(
  "A1"="Was an 'a priori' design provided? The research question and inclusion criteria should be established before the conduct of the review. Note: Need to refer to a protocol, ethics approval, or pre-determined/a priori published research objectives to score a “yes.”",
  "A2"="Was there duplicate study selection and data extraction? There should be at least two independent data extractors and a consensus procedure for disagreements should be in place. Note: 2 people do study selection, 2 people do data extraction, consensus process or one person checks the other’s work.",
  "A3"="Was a comprehensive literature search performed? At least two electronic sources should be searched. The report must include years and databases used (e.g., Central, EMBASE, and MEDLINE). Key words and/or MESH terms must be stated and where feasible the search strategy should be provided. All searches should be supplemented by consulting current contents, reviews, textbooks, specialized registers, or experts in the particular field of study, and by reviewing the references in the studies found. Note: If at least 2 sources + one supplementary strategy used, select “yes” (Cochrane register/Central counts as 2 sources; a grey literature search counts as supplementary).",
  "A4"="Was the status of publication (i.e. grey literature) used as an inclusion criterion? The authors should state that they searched for reports regardless of their publication type. The authors should state whether or not they excluded any reports (from the systematic review), based on their publication status, language etc. Note: If review indicates that there was a search for “grey literature” or “unpublished literature,” indicate “yes.” SIGLE database, dissertations, conference proceedings, and trial registries are all considered grey for this purpose. If searching a source that contains both grey and non-grey, must specify that they were searching for grey/unpublished lit.",
  "A5"="Was a list of studies (included and excluded) provided? A list of included and excluded studies should be provided. Note: Acceptable if the excluded studies are referenced. If there is an electronic link to the list but the link is dead, select “no.”",
  "A6"="Were the characteristics of the included studies provided? In an aggregated form such as a table, data from the original studies should be provided on the participants, interventions and outcomes. The ranges of characteristics in all the studies analyzed e.g., age, race, sex, relevant socioeconomic data, disease status, duration, severity, or other diseases should be reported. Note: Acceptable if not in table format as long as they are described as above. Paul “Follow-up poorly reported in general”",
  "A7"="Was the scientific quality of the included studies assessed and documented? 'A priori' methods of assessment should be provided (e.g., for effectiveness studies if the author(s) chose to include only randomized, double-blind, placebo controlled studies, or allocation concealment as inclusion criteria); for other types of studies alternative items will be relevant. Note: Can include use of a quality scoring tool or checklist, e.g., Jadad scale, risk of bias, sensitivity analysis, etc., or a description of quality items, with some kind of result for EACH study (“low” or “high” is fine, as long as it is clear which studies scored “low” and which scored “high”; a summary score/range for all studies is not acceptable).",
  "A8"="Was the scientific quality of the included studies used appropriately in formulating conclusions? The results of the methodological rigor and scientific quality should be considered in the analysis and the conclusions of the review, and explicitly stated in formulating recommendations. Note: Might say something such as “the results should be interpreted with caution due to poor quality of included studies.” Cannot score “yes” for this question if scored “no” for question A7.",
  "A9"="Were the methods used to combine the findings of studies appropriate? For the pooled results, a test should be done to ensure the studies were combinable, to assess their homogeneity (i.e., Chi-squared test for homogeneity, I2 ). If heterogeneity exists a random effects model should be used and/or the clinical appropriateness of combining should be taken into consideration (i.e., is it sensible to combine?). Note: Indicate “yes” if they mention or describe heterogeneity, i.e., if they explain that they cannot pool because of heterogeneity/variability between interventions.",
  "A10"="Was the likelihood of publication bias assessed? An assessment of publication bias should include a combination of graphical aids (e.g., funnel plot, other available tests) and/or statistical tests (e.g., Egger regression test, Hedges-Olken). Note: If no test values or funnel plot included, score “no”. Score “yes” if mentions that publication bias could not be assessed because there were fewer than 10 included studies.",
  "A11"="Was the conflict of interest included? Potential sources of support should be clearly acknowledged in both the systematic review and the included studies. Note: To get a “yes,” must indicate source of funding or support for the systematic review AND for each of the included studies.",
  "P1"="Title: Identify the report as a systematic review, meta-analysis, or both.",
  "P2"="Abstract / Structured summary: Provide a structured summary including, as applicable: background; objectives; data sources; study eligibility criteria, participants, and interventions; study appraisal and synthesis methods; results; limitations; conclusions and implications of key findings; systematic review registration number.",
  "P3"="Introduction / Rationale: Describe the rationale for the review in the context of what is already known.",
  "P4"="Introduction / Objectives: Provide an explicit statement of questions being addressed with reference to participants, interventions, comparisons, outcomes, and study design (PICOS).",
  "P5"="Methods / Protocol and registration: Indicate if a review protocol exists, if and where it can be accessed (e.g., Web address), and, if available, provide registration information including registration number.",
  "P6"="Methods / Eligibility criteria: Specify study characteristics (e.g., PICOS, length of follow-up) and report characteristics (e.g., years considered, language, publication status) used as criteria for eligibility, giving rationale.",
  "P7"="Methods / Information sources: Describe all information sources (e.g., databases with dates of coverage, contact with study authors to identify additional studies) in the search and date last searched.",
  "P8"="Methods / Search: Present full electronic search strategy for at least one database, including any limits used, such that it could be repeated.",
  "P9"="Methods / Study selection: State the process for selecting studies (i.e., screening, eligibility, included in systematic review, and, if applicable, included in the meta-analysis).",
  "P10"="Methods / Data collection process: Describe method of data extraction from reports (e.g., piloted forms, independently, in duplicate) and any processes for obtaining and confirming data from investigators.",
  "P11"="Methods / Data items: List and define all variables for which data were sought (e.g., PICOS, funding sources) and any assumptions and simplifications made.",
  "P12"="Methods / Risk of bias in individual studies: Describe methods used for assessing risk of bias of individual studies (including specification of whether this was done at the study or outcome level), and how this information is to be used in any data synthesis.",
  "P13"="Methods / Summary measures: State the principal summary measures (e.g., risk ratio, difference in means).",
  "P14"="Methods / Synthesis of results: Describe the methods of handling data and combining results of studies, if done, including measures of consistency (e.g., I2) for each meta-analysis.",
  "P15"="Methods / Risk of bias across studies: Specify any assessment of risk of bias that may affect the cumulative evidence (e.g., publication bias, selective reporting within studies).",
  "P16"="Methods / Additional analyses: Describe methods of additional analyses (e.g., sensitivity or subgroup analyses, meta-regression), if done, indicating which were pre-specified.",
  "P17"="Results / Study selection: Give numbers of studies screened, assessed for eligibility, and included in the review, with reasons for exclusions at each stage, ideally with a flow diagram.",
  "P18"="Results / Study characteristics: For each study, present characteristics for which data were extracted (e.g., study size, PICOS, follow-up period) and provide the citations.",
  "P19"="Results / Risk of bias within studies: Present data on risk of bias of each study and, if available, any outcome level assessment (see item P12).",
  "P20"="Results / Results of individual studies: For all outcomes considered (benefits or harms), present, for each study: (a) simple summary data for each intervention group (b) effect estimates and confidence intervals, ideally with a forest plot.",
  "P21"="Results / Synthesis of results: Present results of each meta-analysis done, including confidence intervals and measures of consistency.",
  "P22"="Results / Risk of bias across studies: Present results of any assessment of risk of bias across studies (see Item P15).",
  "P23"="Results / Additional analysis: Give results of additional analyses, if done (e.g., sensitivity or subgroup analyses, meta-regression [see Item P16]).",
  "P24"="Discussion / Summary of evidence: Summarize the main findings including the strength of evidence for each main outcome; consider their relevance to key groups (e.g., healthcare providers, users, and policy makers).",
  "P25"="Discussion / Limitations: Discuss limitations at study and outcome level (e.g., risk of bias), and at review-level (e.g., incomplete retrieval of identified research, reporting bias).",
  "P26"="Discussion / Conclusions: Provide a general interpretation of the results in the context of other evidence, and implications for future research.",
  "P27"="Funding: Describe sources of funding for the systematic review and other support (e.g., supply of data); role of funders for the systematic review."
)

factorize = function(x) factor(x, levels=c("0","1","NA", "deferred"))
weight_matrix=matrix(c(0,1,1,0, 1,0,1,0, 1,1,0,0, 0,0,0,0), nrow=4)

datatable_scores = function(results, x_rater, y_rater, factorize, weigth_matrix, useNA="no") {
  show_prisma = all(paste0(prisma, "_", y_rater) %in% colnames(results))
  show_amstar = all(paste0(amstar, "_", y_rater) %in% colnames(results))
  
  # Individual publications' ratings
  for (row in rownames(results)) {
    if (show_prisma) {
      prisma_table = table(factorize(unlist(results[row, paste0(prisma, "_", y_rater)])), factorize(unlist(results[row, paste0(prisma, "_", x_rater)])), useNA=useNA)
      results[row, "prisma_agreement"] = calc_agreement(prisma_table)
      results[row, "prisma_cohen_kappa"] = ifelse(results[row, "prisma_agreement"] == 1, 1, cohen.kappa(prisma_table, w=weight_matrix)$weighted.kappa)
      results[row, "prisma_deferring_fraction"] = sum(results[row, paste0(prisma, "_", x_rater)] == "deferred") / length(prisma)
    }
    if (show_amstar) {
      amstar_table = table(factorize(unlist(results[row, paste0(amstar, "_", y_rater)])), factorize(unlist(results[row, paste0(amstar, "_", x_rater)])), useNA=useNA)
      results[row, "amstar_agreement"] = calc_agreement(amstar_table)
      results[row, "amstar_cohen_kappa"] = ifelse(results[row, "amstar_agreement"] == 1, 1, cohen.kappa(amstar_table, w=weight_matrix)$weighted.kappa)
      results[row, "amstar_deferring_fraction"] = sum(results[row, paste0(amstar, "_", x_rater)] == "deferred") / length(amstar)
    }
  }
  
  results$Reference = rownames(results)
  results$author_year_link = paste0("<a href='#", rownames(results), "' title='Jump to individual results on the right'>", results$author_year, "</a>")
  
  columns = c("Reference", "author_year_link")
  colnames = c("Ref.", "Author & Year")
  if (show_prisma) {
    columns = c(columns, "prisma_agreement", "prisma_cohen_kappa")
    colnames = c(colnames, "PRISMA agreement", "PRISMA κ")
    if (sum(results[,"prisma_deferring_fraction"])) {
      columns = c(columns, "prisma_deferring_fraction")
      colnames = c(colnames, "PRISMA deferral")
    }
  }
  if (show_amstar) {
    columns = c(columns, "amstar_agreement", "amstar_cohen_kappa")
    colnames = c(colnames, "AMSTAR agreement", "AMSTAR κ")
    if (sum(results[,"amstar_deferring_fraction"])) {
      columns = c(columns, "amstar_deferring_fraction")
      colnames = c(colnames, "AMSTAR deferral")
    }
  }
  
  datatable(
    results[columns],
    colnames=colnames,
    rownames=F,
    escape=F, 
    options=list(bPaginate=F, dom="t", order=list(list(0, "asc")))
  ) %>% formatPercentage(columns[grepl("agreement", columns) | grepl("deferring", columns)]) %>% formatRound(columns[grepl("kappa", columns)])
}

cat_individual_results = function(results, x_rater, y_rater, quote_accuracy, show_llm_message=T) {
  show_prisma = all(paste0(prisma, "_", y_rater) %in% colnames(results))
  show_amstar = all(paste0(amstar, "_", y_rater) %in% colnames(results))
  
  results[results == "deferred"] = "def."
  
  for (id in rownames(results)) {
    cat("<a name='", id, "'></a>\n\n", sep="")
    cat("#### ", id, ". <a href='", results[id, "link"], "' title='Open publication'>", results[id, "author_year"], ": <i>", results[id, "title"], "</i></a>\n\n", sep="")
    
    if (show_prisma) {
      rownames = paste0("<span style='border-bottom: 1px dashed black' title='", gsub("'", "&#39;", item_instructions[prisma]), "'> ", prisma, "</span>")
      cat(knitr::kable(data.frame(t(data.frame(unlist(results[id, paste0(prisma[1:14], "_", y_rater)]), unlist(results[id, paste0(prisma[1:14], "_", x_rater)]), row.names = rownames[1:14])), row.names=c(y_rater, x_rater), check.names = F), format="html", escape=F, table.attr="style='margin: 0; width: 100%'", caption="PRISMA"), "\n\n")
      cat(knitr::kable(data.frame(t(data.frame(unlist(results[id, paste0(prisma[15:27], "_", y_rater)]), unlist(results[id, paste0(prisma[15:27], "_", x_rater)]), row.names = rownames[15:27])), row.names=c(y_rater, x_rater), check.names = F), format="html", escape=F, table.attr="style='margin: 0; width: 100%; border-top: 0'"), "<br>")
    }
    
    if (show_amstar) {
      rownames = paste0("<span style='border-bottom: 1px dashed black' title='", gsub("'", "&#39;", item_instructions[amstar]), "'> A", 1:11, "</span>")
      cat(knitr::kable(data.frame(t(data.frame(unlist(results[id, paste0(amstar, "_", y_rater)]), unlist(results[id, paste0(amstar, "_", x_rater)]), row.names = rownames)), row.names=c(y_rater, x_rater), check.names = F), format="html", escape=F, table.attr="style='margin: 0; width: 100%'", caption="AMSTAR"), "<br>")
    }
    
    if (show_llm_message) {
      cat_llm_response(id, results[id, "wrong_format"], results[id, "llm_message"], quote_accuracy[quote_accuracy$publication_id == id,])
    }
  }
}
