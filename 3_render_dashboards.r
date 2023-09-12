library(rmarkdown)
library(jsonlite)

tool_folder = "results/prisma_amstar"
notebook = "dashboard_prisma_amstar.rmd"
# tool_folder = "results/precis2"
# notebook = "dashboard_precis2.rmd"

all_params = read_json(paste0(tool_folder, "/params.json"))

for (i in seq_len(length(all_params))) {
  params = all_params[[i]]
  print(params$title)
  render(
    input = paste0(tool_folder, "/", notebook),
    output_file = paste0(params$run_folder, "_", params$output_file, ".html"),
    output_dir = "results/html/",
    output_options = list(title = params$title),
    knit_root_dir = paste0("/home/tim/Forschung/Pragmatic Evidence/Research-Assessment-AI/", tool_folder, "/", params$run_folder, "/"),
    params=params,
    envir=new.env()
  )
}
