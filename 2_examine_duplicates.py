#%%
import os
import json
import re
import numpy as np
import pandas as pd

pragmeta = pd.read_csv("data/pragmeta_random_subset_50.csv", sep=";", index_col=0)
root_folder = "results/prompts/duplicates/"

duplicates_folders = os.listdir(root_folder)
duplicates_folders = list(filter(lambda x: x != "old_prompts", duplicates_folders))

results = []

for folder in duplicates_folders:
    doi = re.search(r"\d\d-\d\d (.*)\.txt", folder).group(1).replace(".tables_removed", "").replace(" ", "/")
    response_files = os.listdir(root_folder + folder)
    response_files = list(filter(lambda x: ("response.json" in x), response_files))
    for response_file in response_files:
        response_json = json.loads(open(root_folder + folder + "/" + response_file).read())
        gpt_message = response_json["choices"][0]["message"]["content"]

        gpt_scores = pd.Series(re.findall(r"Score: \[?(\d|NA)\]", gpt_message)).replace("NA", "NaN").astype("float32").tolist()
        gpt_scores_n = len(gpt_scores)
        gpt_scores.extend([np.nan] * (9-len(gpt_scores)))

        pragmeta_row = pragmeta.loc[pragmeta["trials.doi"].str.lower() == doi.lower(), :].iloc[0]

        results.append({
            "pragmeta_trial_id": pragmeta_row["trials.trials_id"],
            "doi": doi.lower(),
            "prompt_tokens": response_json["usage"]["prompt_tokens"],
            "completion_tokens": response_json["usage"]["completion_tokens"],
            "finish_reason": response_json["choices"][0]["finish_reason"],
            "gpt_scores_n": gpt_scores_n,
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
# %%
