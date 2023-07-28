#%%
import os
import json
import re
import numpy as np
import pandas as pd
from src.functions import *

experiment_folder = "results/AMSTAR-PRISMA/cullis2017_claude/"
prompts_folder = experiment_folder + "prompts/"

response_files = os.listdir(prompts_folder)
response_files = list(filter(lambda x: (".txt" in x), response_files))
response_files.sort()

code = {"Yes": 1, "Partial Yes": 1, "Partial": 1, "No": 0, "Unclear": "NA", "NA": "NA"}
results = []
for response_file in response_files:
    id = int(response_file.split()[0].split(".")[0])
    
    gpt_message = open(prompts_folder + response_file).read()

    gpt_scores = re.findall(r"\[(Yes|Partial Yes|Partial|No|Unclear|NA)\]", gpt_message)
    unsolicitied_answers = False
    if len(re.findall(r"\[(Partial Yes|Partial|Unclear)\]", gpt_message)):
        unsolicitied_answers = True
    ranges = re.findall(r"(P(\d*)-P(\d*)\.)(.*?)\[(Yes|Partial Yes|Partial|No|Unclear|NA)\]", gpt_message.replace("\n", ""))
    original_gpt_scores_n = len(gpt_scores)
    if len(ranges):
        for range in ranges:
            ind = 10 + int(range[1])
            gpt_scores[ind:ind] = [gpt_scores[ind]] * (int(range[2])-int(range[1]))
    if len (gpt_scores) != 38:
        print(f"{response_file}\nWrong number of scores: {len(gpt_scores)}")
        break

    gpt_scores = [code[x] for x in gpt_scores]
    
    results.append({
        "pragmeta_trial_id": id,
        "original_gpt_scores_n": original_gpt_scores_n,
        "unsolicitied_answers": unsolicitied_answers,
        "A1_gpt": gpt_scores[0],
        "A2_gpt": gpt_scores[1],
        "A3_gpt": gpt_scores[2],
        "A4_gpt": gpt_scores[3],
        "A5_gpt": gpt_scores[4],
        "A6_gpt": gpt_scores[5],
        "A7_gpt": gpt_scores[6],
        "A8_gpt": gpt_scores[7],
        "A9_gpt": gpt_scores[8],
        "A10_gpt": gpt_scores[9],
        "A11_gpt": gpt_scores[10],
        "P1_gpt": gpt_scores[11],
        "P2_gpt": gpt_scores[12],
        "P3_gpt": gpt_scores[13],
        "P4_gpt": gpt_scores[14],
        "P5_gpt": gpt_scores[15],
        "P6_gpt": gpt_scores[16],
        "P7_gpt": gpt_scores[17],
        "P8_gpt": gpt_scores[18],
        "P9_gpt": gpt_scores[19],
        "P10_gpt": gpt_scores[20],
        "P11_gpt": gpt_scores[21],
        "P12_gpt": gpt_scores[22],
        "P13_gpt": gpt_scores[23],
        "P14_gpt": gpt_scores[24],
        "P15_gpt": gpt_scores[25],
        "P16_gpt": gpt_scores[26],
        "P17_gpt": gpt_scores[27],
        "P18_gpt": gpt_scores[28],
        "P19_gpt": gpt_scores[29],
        "P20_gpt": gpt_scores[30],
        "P21_gpt": gpt_scores[31],
        "P22_gpt": gpt_scores[32],
        "P23_gpt": gpt_scores[33],
        "P24_gpt": gpt_scores[34],
        "P25_gpt": gpt_scores[35],
        "P26_gpt": gpt_scores[36],
        "P27_gpt": gpt_scores[37],
        "gpt_message": gpt_message
    })

results = pd.DataFrame(results)
results.to_csv(experiment_folder + "results.csv", na_rep="NA", float_format=int, index=False)
results

# %%
