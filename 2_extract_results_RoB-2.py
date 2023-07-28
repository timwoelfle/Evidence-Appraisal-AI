#%%
import json
import re
import pandas as pd
import os

prompts_folder = "results/RoB-2/prompts/23-07-13 signaling_questions_explanations.assignment/"

response_files = os.listdir(prompts_folder)
response_files = list(filter(lambda x: ("response.json" in x), response_files))
response_files.sort()

results = []

for response_file in response_files:
    print(response_file)
    id = response_file.split()[1].split(".")[0]

    response_json = json.loads(open(prompts_folder + response_file).read())
    gpt_message = response_json["choices"][0]["message"]["content"]
    gpt_scores = re.findall(r"\[Response: ([\w ]+)\]", gpt_message)
    
    gpt_scores_n = len(gpt_scores)
    if gpt_scores_n < 22:
        print("Outpot stopped too early! Len =", len(gpt_scores))
        continue
    
    results.append({
        "id": id,
        "prompt_tokens": response_json["usage"]["prompt_tokens"],
        "completion_tokens": response_json["usage"]["completion_tokens"],
        "finish_reason": response_json["choices"][0]["finish_reason"],
        "responses_n": gpt_scores_n,
        "gpt_scores": gpt_scores
    })

results = pd.DataFrame(results)
#results.to_csv("results/23-07-10_results_Toolkit.csv", na_rep="NA", float_format=int, index=False)

# %%
