#%%
import os
import json
import re
import numpy as np
import pandas as pd
from src.functions import *

prompts_folder = "results/PRECIS-2/pragms_pragqol_59/prompts/done/"

response_files = os.listdir(prompts_folder)
response_files = list(filter(lambda x: ("response.json" in x), response_files))
response_files.sort()

results = []
for response_file in response_files:
    id = int(response_file.split()[1].split(".")[0])
    
    response_json = json.loads(open(prompts_folder + response_file).read())
    gpt_message = response_json["choices"][0]["message"]["content"]

    domains = split_domains(gpt_message)
    n_domains = len(domains)
    domains = domains[0:9]
    extracted_domain_names = get_domain_names(domains)
    if len(domains) < 9 or not np.all(np.array(extracted_domain_names) == np.array(domain_names)):
        print(response_file + "\nIssue with domains: " + str(extracted_domain_names))
        break

    gpt_scores = []
    for i in range(len(domains)):
        domain = domains[i]
        domain_scores = get_score(domain)
        if not len(domain_scores):
            print(response_file + "\nNo score found for domain " + extracted_domain_names[i])
            break
        if not all(i == domain_scores[0] for i in domain_scores):
            print(response_file + "\nWarning: Different scores for domain " + extracted_domain_names[i] + ": " + str(domain_scores))
        gpt_scores.append(re.sub("[ \[\]\']", "", str(domain_scores)))
    
    if len (gpt_scores) != 9:
        continue
    
    #gpt_scores = pd.Series(gpt_scores).replace("NA", "NaN").astype("float32").tolist()
    
    results.append({
        "pragmeta_trial_id": id,
        "created": response_json["created"],
        "prompt_tokens": response_json["usage"]["prompt_tokens"],
        "completion_tokens": response_json["usage"]["completion_tokens"],
        "finish_reason": response_json["choices"][0]["finish_reason"],
        "n_sections": n_domains,
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
results.to_csv("results/PRECIS-2/23-07-14_results_Toolkit.csv", na_rep="NA", float_format=int, index=False)
results

# %%
