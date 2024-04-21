#%%
import os
import json
import re
import pandas as pd
from src.compare_quotes import split_interrupted_quotes, compare_quotes

# GPT-3.5
# FULLTEXT_FOLDER = "data/precis2/fulltext/txt/"
# RESULTS_FOLDER = "docs/precis2/gpt3.5_precis2/" # _rep

# Claude-2 Chat
# FULLTEXT_FOLDER = "data/precis2/fulltext/pdf/txt/"
# RESULTS_FOLDER = "docs/precis2/claude2_chat_precis2/" # _rep

# Claude-2 Chat, same prompt as GPT-3.5
# FULLTEXT_FOLDER = "data/precis2/fulltext/txt/"
# RESULTS_FOLDER = "docs/precis2/claude2_chat_gpt3.5_prompt_precis2/"

# Claude-2
# FULLTEXT_FOLDER = "data/precis2/fulltext/pdf/txt/"
# RESULTS_FOLDER = "docs/precis2/claude2_precis2/" # _rep

# GPT-4 (repetition only performed on 25% of publications)
# FULLTEXT_FOLDER = "data/precis2/fulltext/pdf/txt/"
# RESULTS_FOLDER = "docs/precis2/gpt4_precis2/" # _rep

# Mixtral-8x7B
#FULLTEXT_FOLDER = "data/precis2/fulltext/pdf/txt/"
#RESULTS_FOLDER = "docs/precis2/mixtral8x7b_precis2/" # 1773 and 689: extracted scores alright (excluded one summary paragraph)
#RESULTS_FOLDER = "docs/precis2/mixtral8x7b_precis2_rep/" # 1773 and 725: extracted scores alright (excluded one summary paragraph)
#RESULTS_FOLDER = "docs/precis2/mixtral8x7b_gpt4_prompt_precis2/"

# Claude-3-Opus
#FULLTEXT_FOLDER = "data/precis2/fulltext/pdf/txt/"
#RESULTS_FOLDER = "docs/precis2/claude3_opus_precis2/"
#RESULTS_FOLDER = "docs/precis2/claude3_opus_precis2_rep/"
#RESULTS_FOLDER = "docs/precis2/claude3_opus_gpt4_prompt_precis2/" # "655.txt.json Bad finish reason: max_tokens" ok because all scores came before

# Mixtral-8x22B
FULLTEXT_FOLDER = "data/precis2/fulltext/pdf/txt/"
RESULTS_FOLDER = "docs/precis2/mixtral8x22b_precis2/" # _rep

NUM_SCORES = 9

with open(RESULTS_FOLDER + "prompt_template/user.txt") as f:
    prompt = f.read()
if os.path.isfile(RESULTS_FOLDER + "prompt_template/system.txt"):
    with open(RESULTS_FOLDER + "prompt_template/system.txt") as f:
        system_prompt = f.read()
    prompt = system_prompt + "\n" + prompt

responses_folder = RESULTS_FOLDER + "responses/"

response_files = os.listdir(responses_folder)
response_files = list(filter(lambda x: (".txt" in x), response_files))
response_files.sort()

results = []
quote_accuracy = []
for response_file in response_files:
    id = int(response_file.split(".")[0])
    
    llm_message = open(responses_folder + response_file).read()
    if ".json" in response_file:
        response_json = json.loads(llm_message)
        # "choices" seems to be OpenAI's / OpenRouter's syntax
        if "choices" in response_json.keys():
            # "eos" and None are for mixtral
            if "finish_reason" in response_json["choices"][0].keys() and not response_json["choices"][0]["finish_reason"] in ["stop", "stop_sequence", "eos", None]:
                print(f'{response_file}\nBad finish reason: {response_json["choices"][0]["finish_reason"]}')
            llm_message = response_json["choices"][0]["message"]["content"]
        # "content" seems to be Anthropic's syntax
        else:
            if "stop_reason" in response_json and not response_json["stop_reason"] in ["end_turn"]:
                print(f'{response_file}\nBad finish reason: {response_json["stop_reason"]}')
            llm_message = response_json["content"][0]["text"]
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
    
    # Too many scores?
    if len(llm_scores) > NUM_SCORES:
        len_pre = len(llm_scores)
        llm_scores_pre = llm_scores
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
                print(f"{response_file}\nUnable to identify domain_sections - check manually")
                if len(llm_scores_pre) == 10:
                    llm_scores = llm_scores_pre[0:9]
                    wrong_format.append("removed-unsolicited-final-summary-score")
                
        if len(llm_scores) < len_pre:
            wrong_format.append("multiple-scores-per-domain-if-incongruent-na")
    
    if len(llm_scores) != NUM_SCORES:
        print(f"{response_file}\nWrong number of scores: {len(llm_scores)}")
        break

    # Sometimes quotes are interrupted by a gap (...), make sure to exclude that gap from quote
    llm_message = split_interrupted_quotes(llm_message)
    
    prompt_tokens_key = "input_tokens" if "claude3" in RESULTS_FOLDER else "prompt_tokens"
    completion_tokens_key = "output_tokens" if "claude3" in RESULTS_FOLDER else "completion_tokens"
    results.append({
        "publication_id": id,
        #"created": response_json["created"],
        "prompt_tokens": response_json["usage"][prompt_tokens_key] if 'response_json' in locals() and "usage" in response_json else int((len(prompt)+len(fulltext))/4),
        "completion_tokens": response_json["usage"][completion_tokens_key] if 'response_json' in locals() and "usage" in response_json else int(len(original_llm_message)/4),
        #"finish_reason": response_json["choices"][0]["finish_reason"],
        "wrong_format": wrong_format,
        "original_llm_scores_n": original_llm_scores_n,
        "final_llm_scores_n": "",
        "llm_scores": llm_scores,
        "llm_message": llm_message,
        "original_llm_message": original_llm_message,
    })

    with open(FULLTEXT_FOLDER + response_file.replace(".json", "")) as f:
        fulltext = f.read()
    quote_accuracy += [{"publication_id": id, "tool": "PRECIS-2", **x} for x in compare_quotes(llm_message, fulltext, prompt)]

results = pd.DataFrame(results).set_index("publication_id")
results.to_csv(RESULTS_FOLDER + "results.csv", na_rep="NA")

quote_accuracy = pd.DataFrame(quote_accuracy)
quote_accuracy.to_csv(RESULTS_FOLDER + "quote_accuracy.csv", na_rep="NA", index=False)

results

# %%
