#%%
import os
import json
import re
import pandas as pd
from src.extract_results import compare_quotes

# Experiments 3 & 4
FULLTEXT_FOLDER = "data/PRECIS-2/pragms-pragqol-56/fulltext/txt/done/"
RESULTS_FOLDER = "results/PRECIS-2/pragms-pragqol-56_toolkit_gpt3.5/" # _rep
NUM_SCORES = 9
with open(RESULTS_FOLDER + "prompt_template/system.txt") as f:
    system_prompt = f.read()
with open(RESULTS_FOLDER + "prompt_template/user.txt") as f:
    user_prompt = f.read()
prompt = system_prompt + "\n" + user_prompt

responses_folder = RESULTS_FOLDER + "responses/"

response_files = os.listdir(responses_folder)
response_files = list(filter(lambda x: (".json" in x), response_files))
response_files.sort()

results = []
quote_accuracy = []
for response_file in response_files:
    id = int(response_file.split(".")[0])
    
    response_json = json.loads(open(responses_folder + response_file).read())
    llm_message = response_json["choices"][0]["message"]["content"]
    original_llm_message = llm_message

    llm_scores = re.findall(r"Score: \[(\d|NA)\]", llm_message)
    original_llm_scores_n = len(llm_scores)

    wrong_format = []
    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"(?<!\[NA\])Not applicable\.(?!=\[NA\])", r"Not applicable. <added>Score: [NA]</added>", llm_message)
        llm_scores = re.findall(r"Score: \[(\d|NA)\]", llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("not-applicable-without-score")

    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"\[Score: (\d|NA)\]", r"<moved-squared-brackets>Score: [\1]</moved-squared-brackets>", llm_message)
        llm_scores = re.findall(r"Score: \[(\d|NA)\]", llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("squared-brackets-around-score")
    
    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"(?<![Ss]core): \[(\d|NA)\]", r": <added-score-prefix>Score: [\1]</added-score-prefix>", llm_message)
        llm_scores = re.findall(r"Score: \[(\d|NA)\]", llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("score-prefix-missing-before-colon")
    
    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"(?<![Ss]core: )\[NA\]", r"<added-score-prefix>Score: [NA]</added-score-prefix>", llm_message)
        llm_scores = re.findall(r"Score: \[(\d|NA)\]", llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("score-prefix-missing-before-na")
    
    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"(?<![Ss]core: )\[(\d)\]", r"<added-score-prefix>Score: [\1]</added-score-prefix>", llm_message)
        llm_scores = re.findall(r"Score: \[(\d|NA)\]", llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("score-prefix-missing-before-number")
    
    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = llm_message.replace("N/A", "N/A <added>Score: [NA]</added>")
        llm_scores = re.findall(r"Score: \[(\d|NA)\]", llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-score-na-with-slash")
    
    if len(llm_scores) > NUM_SCORES:
        len_pre = len(llm_scores)
        domain_sections = llm_message.split("\n\n")
        llm_scores = []
        # Sometimes a summary paragraph is at the bottom, which has to be ignored
        if len(domain_sections) in (9, 10):
            for i in range(9):
                domain_scores = re.findall(r"Score: \[(\d|NA)\]", domain_sections[i])
                llm_scores.append(domain_scores[0] if len(set(domain_scores)) == 1 else "NA")
        else:
            domain_sections = llm_message.split(":\n")
            if len(domain_sections) == 10:
                for i in range(9):
                    domain_scores = re.findall(r"Score: \[(\d|NA)\]", domain_sections[1+i])
                    llm_scores.append(domain_scores[0] if len(set(domain_scores)) == 1 else "NA")
            else:
                print(f"{response_file}\nUnable to identify domain_sections")
        if len(llm_scores) < len_pre:
            wrong_format.append("multiple-scores-per-domain-if-incongruent-na")
    
    if len(llm_scores) != NUM_SCORES:
        print(f"{response_file}\nWrong number of scores: {len(llm_scores)}")
        break
    
    results.append({
        "publication_id": id,
        "created": response_json["created"],
        "prompt_tokens": response_json["usage"]["prompt_tokens"],
        "completion_tokens": response_json["usage"]["completion_tokens"],
        "finish_reason": response_json["choices"][0]["finish_reason"],
        "wrong_format": wrong_format,
        "original_llm_scores_n": original_llm_scores_n,
        "final_llm_scores_n": "",
        "llm_scores": llm_scores,
        "llm_message": llm_message,
        "original_llm_message": original_llm_message,
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
