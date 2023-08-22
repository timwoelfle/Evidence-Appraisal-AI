#%%
import os
import re
import pandas as pd
from src.extract_results import compare_quotes

# Experiment 1 & 2
# FULLTEXT_FOLDER = "data/PRECIS-2/pragms-pragqol-56/pdf/txt/"
# RESULTS_FOLDER = "results/PRECIS-2/pragms-pragqol-56_loudon2015-toolkit_claude2/" # _rep
# NUM_SCORES = 9
# with open(RESULTS_FOLDER + "prompt_template/user.txt") as f:
#     user_prompt = f.read()
# with open(RESULTS_FOLDER + "prompt_template/Loudon 2015.pdf.txt") as f:
#     loudon2015_prompt = f.read()
# with open(RESULTS_FOLDER + "prompt_template/PRECIS Toolkit.pdf.txt") as f:
#     toolkit_prompt = f.read()
# prompt = user_prompt + "\n" + loudon2015_prompt + "\n" + toolkit_prompt

# Experiment 5
FULLTEXT_FOLDER = "data/PRECIS-2/pragms-pragqol-56/txt/done/"
RESULTS_FOLDER = "results/PRECIS-2/pragms-pragqol-56_toolkit_claude2/"
NUM_SCORES = 9
with open(RESULTS_FOLDER + "prompt_template/user.txt") as f:
    prompt = f.read()

responses_folder = RESULTS_FOLDER + "responses/"

response_files = os.listdir(responses_folder)
response_files = list(filter(lambda x: (".txt" in x), response_files))
response_files.sort()

results = []
quote_accuracy = []
for response_file in response_files:
    id = int(response_file.split(".")[0])
    
    llm_message = open(responses_folder + response_file).read()

    llm_scores = re.findall(r"Score: \[(\d|NA)\]", llm_message)
    
    if len (llm_scores) != NUM_SCORES:
        print(f"{response_file}\nWrong number of scores: {len(llm_scores)}")
        break
    
    results.append({
        "publication_id": id,
        "wrong_format": [],
        "llm_scores": llm_scores,
        "llm_message": llm_message,
    })

    with open(FULLTEXT_FOLDER + response_file.replace(".json", "")) as f:
        fulltext = f.read()
    quote_accuracy += [{"publication_id": id, **x} for x in compare_quotes(llm_message, fulltext, prompt)]

results = pd.DataFrame(results).set_index("publication_id")
results.to_csv(RESULTS_FOLDER + "results.csv", na_rep="NA")

quote_accuracy = pd.DataFrame(quote_accuracy)
quote_accuracy.to_csv(RESULTS_FOLDER + "quote_accuracy.csv", na_rep="NA", index=False)

results

# %%
