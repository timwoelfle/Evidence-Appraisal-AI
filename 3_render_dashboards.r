library(rmarkdown)
library(jsonlite)

# source("src/results_functions_prisma_amstar.r") # prisma, amstar
# TOOL_FOLDER = "prisma_amstar/"
# NOTEBOOK_FILE = "dashboard_prisma_amstar.rmd"
source("src/results_functions_precis2.r") # precis2
TOOL_FOLDER = "precis2/"
NOTEBOOK_FILE = "dashboard_precis2.rmd"

all_params = read_json(paste0("results/", TOOL_FOLDER, "params.json"))

render_dashboard = function(params) render(
  input = paste0("results/", TOOL_FOLDER, NOTEBOOK_FILE),
  output_file = paste0(params$run_folder, "_", params$output_file, ".html"),
  output_dir = "results/html/",
  output_options = list(title = params$title),
  knit_root_dir = paste0("/home/tim/Forschung/Pragmatic Evidence/Research-Assessment-AI/results/", TOOL_FOLDER, params$run_folder, "/"),
  params=params,
  envir=new.env()
)

combine_human_ai = function(human_rater_no, params) {
  human_rater = read.csv(paste0("data/", TOOL_FOLDER, "rater", human_rater_no, ".csv"), row.names = 1, na.strings = NULL, check.names = F)
  
  items = switch(params$tool, "prisma"=prisma, "amstar"=amstar, "prisma_amstar"=c(amstar, prisma), "precis2"=precis2)
  results = read.csv(paste0("results/", TOOL_FOLDER, params$run_folder, "/results.csv"), row.names = 1, na.strings = NULL, check.names = F)
  if (!all(items %in% colnames(results))) {
    results[items] = t(sapply(strsplit(gsub("\\[|\\]|\\'", "", results$llm_scores), ", ", fixed=T), as.character)) # strtoi
  }
  
  human_rater = human_rater[rownames(human_rater) %in% rownames(results),]
  results = results[rownames(results) %in% rownames(human_rater),]
  
  for (row in rownames(results)) {
    results[row, items] = ifelse(results[row, items] == human_rater[row, items], results[row, items], "deferred")
  }
  results = results[items]
  
  run_folder = paste0("human_rater", human_rater_no, "_", params$run_folder)
  dir.create(paste0("results/", TOOL_FOLDER, run_folder), showWarnings = F)
  write.csv(results, paste0("results/", TOOL_FOLDER, run_folder, "/results.csv"))
  
  x_rater = paste0("Human Rater ", human_rater_no, " & ", params$x_rater)
  params = list(
    "run_folder"=run_folder, "rater"=params$rater, "tool"=params$tool,
    "title"=paste0(sub("_", " & ", toupper(params$tool)), " in Cullis 2017: ", x_rater, " vs Human Consensus (Accuracy)"),
    "output_file"="human_consensus",
    "x_rater"=x_rater,
    "show_llm_message"=F
  )
  
  render_dashboard(params)
}

for (i in seq_len(length(all_params))) {
  params = all_params[[i]]
  print(params$title)
  
  render_dashboard(params)
  
  # Create Human-AI collaboration dashboards
  if (params$output_file != "human_consensus" | grepl("human_rater", params$rater) | params$run_folder %in% c("gpt4_prisma_amstar_rep", "gpt4_precis2_rep")) next
  
  ## Human-AI collaboration results
  combine_human_ai(1, params)
  combine_human_ai(2, params)
}
