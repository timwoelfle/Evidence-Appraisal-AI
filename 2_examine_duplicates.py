#%%
import os
import json
import re
import pandas as pd

root_folder = "results/prompts/duplicates/"

duplicates_folders = os.listdir(root_folder)

gpt_scores = {}

for folder in duplicates_folders:
    response_files = os.listdir(root_folder + folder)
    response_files = list(filter(lambda x: ("response.json" in x), response_files))
    gpt_messages = [
        json.loads(open(root_folder + folder + "/"  + response_file).read())["choices"][0]["message"]["content"] 
        for response_file in response_files
    ]
    gpt_scores[folder] = [
        pd.Series(re.findall(r"Score: \[?(\d|NA)\]", gpt_message)).replace("NA", "NaN").astype("float32").tolist()
        for gpt_message in gpt_messages
    ]

# TODO: systematically compare duplicates (eg. length, SSE, kappa of NA, ...)
