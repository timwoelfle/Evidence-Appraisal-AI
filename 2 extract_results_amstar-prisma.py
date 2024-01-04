#%%
import os
import json
import re
import pandas as pd
from src.compare_quotes import split_interrupted_quotes, compare_quotes

# Experiments 1 & 2 (GPT-3.5)
# AMSTAR: 11:107, 14:3, 12:1, 22:1
# AMSTAR rep: 11:110, 22:1, 12:1
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/gpt3.5_amstar/" # _rep
# NUM_SCORES = 11
# PRISMA: 109
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/gpt3.5_prisma/" # _rep
# NUM_SCORES = 27

# Experiment 3 & 4 (Claude-2 chat)
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/claude2_chat_prisma_amstar_rep/" # _rep
# NUM_SCORES = 38

# Experiment 5 (Claude-2 chat, same prompt as GPT-3.5)
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/claude2_chat_gpt3.5_prompt_prisma/"
# NUM_SCORES = 27
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/claude2_chat_gpt3.5_prompt_amstar/"
# NUM_SCORES = 11

# Experiment 6 & 7 (Claude-2 API)
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/claude2_prisma_amstar/" # _rep
# NUM_SCORES = 38

# Experiment 8 (repetition only performed on 25% of publications) (GPT-4): 109
FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/txt/"
RESULTS_FOLDER = "docs/prisma_amstar/gpt4_prisma_amstar_rep/" # _rep
NUM_SCORES = 38

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
        if not response_json["choices"][0]["finish_reason"] in ["stop", "stop_sequence"]:
            print(f'{response_file}\nOutput interrupted because of length: {response_json["choices"][0]["finish_reason"]}')
            continue
        llm_message = response_json["choices"][0]["message"]["content"]
    original_llm_message = llm_message
    
    ### Extract ratings ("scores") and fix minor formatting issues
    def find_scores(llm_message):
        llm_scores = re.findall(r"\[(Yes|No|NA)\]", llm_message)
        ranges = re.findall(r"(P(\d*)-P(\d*)\.)(.*?)\[(Yes|No|NA)\]", llm_message.replace("\n", ""))
        if len(ranges):
            for range in ranges:
                ind = 10 + int(range[1])
                llm_scores[ind:ind] = [llm_scores[ind]] * (int(range[2])-int(range[1]))
        return (llm_scores)

    llm_scores = find_scores(llm_message)
    original_llm_scores_n = len(llm_scores)

    wrong_format = []

    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"\[(Partial Yes|Partial|Partially|Adequate)\]", r"[\1 <added>[Yes]</added>]", llm_message)
        llm_message = re.sub(r"\[(Inadequate)\]", r"[\1 <added>[No]</added>]", llm_message)
        llm_message = re.sub(r"\[(Unclear|Insufficient information|It is unclear|Yes/No)\]", r"[\1 <added>[NA]</added>]", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("wrong-response-partial-unclear-etc")
    
    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"([A|P]\d+. )Yes(?!\w)(?!.*\[Yes\])", r"\1<added-squared-brackets>[Yes]</added-squared-brackets>", llm_message)
        llm_message = re.sub(r"([A|P]\d+. )No(?!\w)(?!.*\[No\])", r"\1<added-squared-brackets>[No]</added-squared-brackets>", llm_message)
        llm_message = re.sub(r"([A|P]\d+. )NA(?!\w)(?!.*\[NA\])", r"\1<added-squared-brackets>[NA]</added-squared-brackets>", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-in-numbered-list")
    
    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub("(?<!\w)NA(?!\w)(?!.*\[NA\])", "<added-squared-brackets>[NA]</added-squared-brackets>", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-for-na")

    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"Not applicable(?!.*\[NA\])", "Not applicable <added>[NA]</added>", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("not-applicable-missing-na-in-squared-brackets")
    
    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"\n- Yes(?!\w)(?!.*\[Yes\])(?=.*\n\n|.*$)", r"\n- <added-squared-brackets>[Yes]</added-squared-brackets>", llm_message)
        llm_message = re.sub(r"\n- No(?!\w)(?!.*\[No\])(?=.*\n\n|.*$)", r"\n- <added-squared-brackets>[No]</added-squared-brackets>", llm_message)
        llm_message = re.sub(r"\n- NA(?!\w)(?!.*\[NA\])(?=.*\n\n|.*$)", r"\n- <added-squared-brackets>[NA]</added-squared-brackets>", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-in-unnumbered-list")

    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"\n- (Partial Yes|Partial|Partially|Adequate)(?!\w)(?!.*\[Yes\])", r"\n- \1 <added>[Yes]</added>", llm_message)
        llm_message = re.sub(r"\n- (Inadequate)(?!\w)(?!.*\[No\])", r"\n- \1 <added>[No]</added>", llm_message)
        llm_message = re.sub(r"\n- (Unclear|Insufficient information|It is unclear|Yes/No)(?!\w)(?!.*\[NA\])", r"\n- \1 <added>[NA]</added>", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("wrong-response-partial-unclear-etc-without-squared-brackets")

    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"(Yes|No|NA) *\n", r"<added-squared-brackets>[\1]</added-squared-brackets>\n", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-end-of-line")
    
    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"(Yes|No|NA) -", r"<added-squared-brackets>[\1]</added-squared-brackets> -", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-pre-dash")
    
    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = llm_message.replace("N/A", "N/A <added>[NA]</added>")
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-na-with-slash")

    # Same response twice in the same row => remove second
    if len(llm_scores) > NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"(.*)\[Yes\](.*)\[Yes\]", r"\1[Yes]\2", llm_message)
        llm_message = re.sub(r"(.*)\[No\](.*)\[No\]", r"\1[Yes]\2", llm_message)
        llm_message = re.sub(r"(.*)\[NA\](.*)\[NA\]", r"\1[Yes]\2", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("same-response-twice-in-a-row-(removed-second)")

    ranges = re.findall(r"(P(\d*)-P(\d*)\.)(.*?)\[(Yes|No|NA)\]", llm_message.replace("\n", ""))
    if len(ranges):
        wrong_format.append("unsolicited-ranges")

    final_llm_scores_n = len(llm_scores)
    if len(llm_scores) > NUM_SCORES:
        llm_scores = llm_scores[0:NUM_SCORES]
    
    code = {"Yes": 1, "No": 0, "NA": "NA"}
    llm_scores = [code[x] for x in llm_scores]

    if len(llm_scores) != NUM_SCORES:
        print(f"{response_file}\nWrong number of scores: {len(llm_scores)}")
        break

    # Sometimes quotes are interrupted by a gap (...), make sure to exclude that gap from quote
    llm_message = split_interrupted_quotes(llm_message)

    results.append({
        "publication_id": id,
        #"created": response_json["created"],
        "prompt_tokens": response_json["usage"]["prompt_tokens"] if 'response_json' in locals() and "usage" in response_json else int((len(prompt)+len(fulltext))/4),
        "completion_tokens": response_json["usage"]["completion_tokens"] if 'response_json' in locals() and "usage" in response_json else int(len(original_llm_message)/4),
        #"finish_reason": response_json["choices"][0]["finish_reason"],
        "wrong_format": wrong_format,
        "original_llm_scores_n": original_llm_scores_n,
        "final_llm_scores_n": final_llm_scores_n,
        "llm_scores": llm_scores,
        "llm_message": llm_message,
        "original_llm_message": original_llm_message,
    })

    with open(FULLTEXT_FOLDER + response_file.replace(".json", "")) as f:
        fulltext = f.read()
    # If PRISMA and AMSTAR are combined, split llm_message and compare quotes separately
    if NUM_SCORES == 38:
        llm_message_split = llm_message.split("P1.")
        if len(llm_message_split) == 1:
            llm_message_split = llm_message.split("P1:")
        if len(llm_message_split) > 2:
            print(f"{response_file}\Warning! More than 2 splits for 'P1.': {llm_message_split}")
        quote_accuracy += [{"publication_id": id, "tool": "AMSTAR", **x} for x in compare_quotes(llm_message_split[0], fulltext, prompt)]
        quote_accuracy += [{"publication_id": id, "tool": "PRISMA", **x} for x in compare_quotes(llm_message_split[1], fulltext, prompt)]
    else:
        quote_accuracy += [{"publication_id": id, "tool": "PRISMA" if NUM_SCORES == 27 else "AMSTAR",  **x} for x in compare_quotes(llm_message, fulltext, prompt)]

results = pd.DataFrame(results).set_index("publication_id")
results.to_csv(RESULTS_FOLDER + "results.csv", na_rep="NA")
print(results["final_llm_scores_n"].value_counts())

quote_accuracy = pd.DataFrame(quote_accuracy)
quote_accuracy.to_csv(RESULTS_FOLDER + "quote_accuracy.csv", na_rep="NA", index=False)

results

# %%
