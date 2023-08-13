#%%
import os
import pandas as pd
from src.extract_results import extract_prisma_amstar, compare_quotes

FULLTEXT_FOLDER = "data/PRISMA-AMSTAR/cullis2017/fulltext/txt/done/"
RESULTS_FOLDER = "results/PRISMA-AMSTAR/cullis2017_prisma_claude2/"
NUM_SCORES = 27
# FULLTEXT_FOLDER = "data/PRISMA-AMSTAR/cullis2017/fulltext/txt/done/"
# RESULTS_FOLDER = "results/PRISMA-AMSTAR/cullis2017_amstar_claude2/"
# NUM_SCORES = 11
# FULLTEXT_FOLDER = "data/PRISMA-AMSTAR/cullis2017/fulltext/pdf/txt/"
# RESULTS_FOLDER = "results/PRISMA-AMSTAR/cullis2017_amstar-prisma_claude2/"
# NUM_SCORES = 38

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
    original_llm_message = llm_message
    
    (wrong_format, original_llm_scores_n, final_llm_scores_n, llm_scores, llm_message) = extract_prisma_amstar(llm_message, NUM_SCORES)

    if len(llm_scores) != NUM_SCORES:
        print(f"{response_file}\nWrong number of scores: {len(llm_scores)}")
        break

    results.append({
        "publication_id": id,
        "wrong_format": wrong_format,
        "original_llm_scores_n": original_llm_scores_n,
        "final_llm_scores_n": final_llm_scores_n,
        "llm_scores": llm_scores,
        "llm_message": llm_message,
        "original_llm_message": original_llm_message,
    })

    with open(FULLTEXT_FOLDER + response_file.replace(".json", "")) as f:
        fulltext = f.read()
    quote_accuracy += [{"publication_id": id, **x} for x in compare_quotes(llm_message, fulltext, prompt)]

results = pd.DataFrame(results).set_index("publication_id")
results.to_csv(RESULTS_FOLDER + "results.csv", na_rep="NA")
print(results["final_llm_scores_n"].value_counts())

quote_accuracy = pd.DataFrame(quote_accuracy)
quote_accuracy.to_csv(RESULTS_FOLDER + "quote_accuracy.csv", na_rep="NA", index=False)

results

# %%
