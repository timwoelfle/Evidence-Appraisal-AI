#%%
import json
import re
import pandas as pd
import os

pragmeta = pd.read_csv("data/pragmeta_random_subset_50.csv", sep=";", index_col=0)

prompts_folder = "results/prompts/23-07-04 30 fulltexts 2Toolkit/"

response_files = os.listdir(prompts_folder)
response_files = list(filter(lambda x: ("response.json" in x), response_files))

results = []

for response_file in response_files:
    print(response_file)
    doi = re.search(r"\d\d:\d\d (.*)\.txt", response_file).group(1).replace(" ", "/")

    response_json = json.loads(open(prompts_folder + response_file).read())
    gpt_message = response_json["choices"][0]["message"]["content"]
    

    gpt_scores = pd.Series(re.findall(r"Score: \[(\d|NA)\]", gpt_message)).replace("NA", "NaN").astype("float32").tolist()
    wrong_format = False
    if not len(gpt_scores):
        gpt_scores = pd.Series(re.findall(r"\[Score: (\d|NA)]", gpt_message)).replace("NA", "NaN").astype("float32").tolist()
        wrong_format = True
    
    pragmeta_row = pragmeta.loc[pragmeta["trials.doi"].str.lower() == doi.lower(), :].iloc[0]
    human_scores = pragmeta_row[["precis2.eligibility_score", "precis2.recruit_score", "precis2.set_score", "precis2.org_score", "precis2.flex_score", "precis2.adherence_score", "precis2.fu_score", "precis2.out_score", "precis2.analysis_score"]]
    human_scores[human_scores == "consensus"] = "NaN"
    human_scores = human_scores.astype("float32").tolist()
    
    results.append({
        "pragmeta_trial_id": pragmeta_row["trials.trials_id"],
        "doi": doi.lower(),
        "prompt_tokens": response_json["usage"]["prompt_tokens"],
        "completion_tokens": response_json["usage"]["completion_tokens"],
        "finish_reason": response_json["choices"][0]["finish_reason"],
        "wrong_format": wrong_format,
        "gpt_score_eligibility": gpt_scores[0],
        "human_score_eligibility": human_scores[0],
        "gpt_score_recruitment": gpt_scores[1],
        "human_score_recruitment": human_scores[1],
        "gpt_score_setting": gpt_scores[2],
        "human_score_setting": human_scores[2],
        "gpt_score_organization": gpt_scores[3],
        "human_score_organization": human_scores[3],
        "gpt_score_flexibility_delivery": gpt_scores[4],
        "human_score_flexibility_delivery": human_scores[4],
        "gpt_score_flexibility_adherence": gpt_scores[5],
        "human_score_flexibility_adherence": human_scores[5],
        "gpt_score_followup": gpt_scores[6],
        "human_score_followup": human_scores[6],
        "gpt_score_primary_outcome": gpt_scores[7],
        "human_score_primary_outcome": human_scores[7],
        "gpt_score_primary_analysis": gpt_scores[8],
        "human_score_primary_analysis": human_scores[8],
        "gpt_message": gpt_message
    })

results = pd.DataFrame(results)
results.to_csv("results/23-07-04_results.csv", na_rep="NA", float_format=int, index=False)

# %%
import pandas as pd
import plotly.express as px
from plotly.subplots import make_subplots

results = pd.read_csv("results/23-07-04_results.csv")
domains = ["eligibility", "recruitment", "setting", "organization", "flexibility_delivery", "flexibility_adherence", "followup", "primary_outcome", "primary_analysis"]

fig = make_subplots(rows=3, cols=3)

for i in range(9):
    z = pd.crosstab(results["human_score_" + domains[i]].fillna("NA").astype(pd.CategoricalDtype([1, 2, 3, 4, 5, "NA"], ordered=True)), results["gpt_score_" + domains[i]].fillna("NA").astype(pd.CategoricalDtype([1, 2, 3, 4, 5, "NA"], ordered=True)), dropna=False).values

    fig.add_trace(px.imshow(z, text_auto=True).data[0], row=1+int(i/3), col=1+(i%3))

fig.update_layout(
    margin=dict(l=20, r=20, t=20, b=20)
)
fig.show()

# %%
