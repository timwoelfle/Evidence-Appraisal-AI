#%%
import json
import re
import pandas as pd
import os

pragmeta = pd.read_csv("data/PRECIS-2/2023-06-07-PragMeta-export-V1_TW.csv", sep=";", index_col="trials.trials_id")

prompts_folder = "results/PRECIS-2/prompts/Prag/"

response_files = os.listdir(prompts_folder)
response_files = list(filter(lambda x: ("response.json" in x), response_files))
response_files.sort()

results = []
for response_file in response_files:
    print(response_file)
    id = int(response_file.split()[1].split(".")[0])
    
    response_json = json.loads(open(prompts_folder + response_file).read())
    gpt_message = response_json["choices"][0]["message"]["content"]
    
    gpt_scores = pd.Series(re.findall(r"Score: \[?(\d|NA)\]", gpt_message)).replace("NA", "NaN").astype("float32").tolist()
    # wrong_format = False
    # if not len(gpt_scores):
    #     gpt_scores = pd.Series(re.findall(r"\Score: (\d|NA)]", gpt_message)).replace("NA", "NaN").astype("float32").tolist()
    #     wrong_format = True
    # if not len(gpt_scores):
    #     gpt_scores = pd.Series(re.findall(r"\: \[?(\d|NA)]", gpt_message)).replace("NA", "NaN").astype("float32").tolist()
    #     wrong_format = True
    gpt_scores_n = len(gpt_scores)
    if gpt_scores_n < 9:
        print("Outpot stopped too early! Len =", len(gpt_scores))
        continue
    
    human_scores = pragmeta.loc[id, ["precis2.eligibility_score", "precis2.recruit_score", "precis2.set_score", "precis2.org_score", "precis2.flex_score", "precis2.adherence_score", "precis2.fu_score", "precis2.out_score", "precis2.analysis_score"]]
    human_scores[human_scores == "consensus"] = "NaN"
    human_scores = human_scores.astype("float32").tolist()
    
    results.append({
        "pragmeta_trial_id": id,
        "doi": pragmeta.loc[id, "trials.doi"],
        "prompt_tokens": response_json["usage"]["prompt_tokens"],
        "completion_tokens": response_json["usage"]["completion_tokens"],
        "finish_reason": response_json["choices"][0]["finish_reason"],
        "gpt_scores_n": gpt_scores_n,
        #"wrong_format": wrong_format,
        "eligibility_gpt": gpt_scores[0],
        "eligibility_human": human_scores[0],
        "recruitment_gpt": gpt_scores[1],
        "recruitment_human": human_scores[1],
        "setting_gpt": gpt_scores[2],
        "setting_human": human_scores[2],
        "organization_gpt": gpt_scores[3],
        "organization_human": human_scores[3],
        "flexibility_delivery_gpt": gpt_scores[4],
        "flexibility_delivery_human": human_scores[4],
        "flexibility_adherence_gpt": gpt_scores[5],
        "flexibility_adherence_human": human_scores[5],
        "followup_gpt": gpt_scores[6],
        "followup_human": human_scores[6],
        "primary_outcome_gpt": gpt_scores[7],
        "primary_outcome_human": human_scores[7],
        "primary_analysis_gpt": gpt_scores[8],
        "primary_analysis_human": human_scores[8],
        "gpt_message": gpt_message
    })

results = pd.DataFrame(results)
results.to_csv("results/PRECIS-2/23-07-14_results_Toolkit.csv", na_rep="NA", float_format=int, index=False)

# %%
