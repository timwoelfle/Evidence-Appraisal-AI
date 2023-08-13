#%%
import os
import re
import pandas as pd

experiment_folder = "results/PRECIS-2/pragms_pragqol_56_claude/"
prompts_folder = experiment_folder + "prompts/done/"

response_files = os.listdir(prompts_folder)
response_files = list(filter(lambda x: ("response.txt" in x), response_files))
response_files.sort()

results = []
for response_file in response_files:
    id = int(response_file.split()[1].split(".")[0])
    
    gpt_message = open(prompts_folder + response_file).read()

    gpt_scores = re.findall(r"Score: \[(\d|NA)\]", gpt_message)
    
    if len (gpt_scores) != 9:
        print(response_file + "\nWrong number of scores: " + len(gpt_scores))
        continue
    
    results.append({
        "pragmeta_trial_id": id,
        "gpt_scores_n": len(gpt_scores),
        "eligibility_gpt": gpt_scores[0],
        "recruitment_gpt": gpt_scores[1],
        "setting_gpt": gpt_scores[2],
        "organization_gpt": gpt_scores[3],
        "flexibility_delivery_gpt": gpt_scores[4],
        "flexibility_adherence_gpt": gpt_scores[5],
        "followup_gpt": gpt_scores[6],
        "primary_outcome_gpt": gpt_scores[7],
        "primary_analysis_gpt": gpt_scores[8],
        "gpt_message": gpt_message
    })

results = pd.DataFrame(results)
results.to_csv(experiment_folder + "23-07-18_results.csv", na_rep="NA", float_format=int, index=False)
results

# %%
