#%%
import os
import numpy as np
import pandas as pd
from rapidfuzz import fuzz, utils
import parasail
#from difflib import SequenceMatcher
from src.functions import *

quote_quality = []

experiment = "PRECIS-2/pragms_pragqol_56"

results = pd.read_csv("results/" + experiment + "_gpt/23-07-14_results_Toolkit.csv", index_col="pragmeta_trial_id")

fulltext_path = "data/" + experiment + "/fulltext/done/"
fulltext_files = np.array(os.listdir(fulltext_path))

for id in results.index:
    file = fulltext_files[np.char.find(fulltext_files, str(id)) != -1]
    if len(file) > 1:
        print("WARNING: more than one fulltext file found: " + file)
    fulltext = open(fulltext_path + file[0]).read()
    quotes = extract_quotes(results.loc[id, "gpt_message"])
    
    for domain_name, domain_quotes in quotes.items():
        if not len(domain_quotes):
            continue

        best_matches = []
        ratios = []
        for quote in domain_quotes:
            best_paragraph = process.extractOne(quote, fulltext.split("\n"), scorer=fuzz.partial_ratio)[0]
            if fulltext.find(quote) != -1:
                best_matches.append(quote)
                ratios.append(100)
            else:
                # Directly using fuzz.partial_ratio_alignment often cuts reference strings short
                # (Compare: https://github.com/maxbachmann/RapidFuzz/issues/323)
                # Workaround: try using parasail with Smith Waterman to identify best_match first
                # ssw = parasail.ssw(utils.default_process(quote), utils.default_process(best_paragraph), 10, 1, parasail.blosum50)
                # if ssw != None:
                #     best_matches.append(best_paragraph[ssw.ref_begin1:ssw.ref_end1+1])
                #     ratios.append(fuzz.partial_ratio(quote, best_matches[-1]))
                # else:
                pra = fuzz.partial_ratio_alignment(quote, fulltext, processor=utils.default_process)
                best_matches.append(fulltext[pra.dest_start:pra.dest_end])
                ratios.append(pra.score)
        
            quote_quality.append({
                "pragmeta_trial_id": id,
                "domain_name": domain_name,
                "quote": quote,
                "best_match": best_matches[-1],
                "best_paragraph": best_paragraph,
                "ratio": ratios[-1],
            })
        
quote_quality = pd.DataFrame(quote_quality)
quote_quality

#%%
quote_quality.to_csv("results/23-07-14_quote_quality_Toolkit.csv", index=False)
# %%
