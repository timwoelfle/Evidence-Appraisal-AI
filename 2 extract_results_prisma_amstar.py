#%%
import os
import json
import re
import pandas as pd
from src.compare_quotes import split_interrupted_quotes, compare_quotes

# GPT-3.5
# AMSTAR: 11:107, 14:3, 12:1, 22:1
# AMSTAR rep: 11:110, 22:1, 12:1
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/gpt3.5_amstar/" # _rep
# NUM_SCORES = 11
# PRISMA: 109
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/gpt3.5_prisma/" # _rep
# NUM_SCORES = 27

# Claude-2 Chat
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/claude2_chat_prisma_amstar/" # _rep
# NUM_SCORES = 38

# Claude-2 Chat, same prompt as GPT-3.5
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/claude2_chat_gpt3.5_prompt_prisma/"
# NUM_SCORES = 27
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/claude2_chat_gpt3.5_prompt_amstar/"
# NUM_SCORES = 11

# Claude-2
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/claude2_prisma_amstar/" # _rep
# NUM_SCORES = 38

# GPT-4: 109 (repetition, only performed on 25% of publications)
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/gpt4_prisma_amstar/" # _rep
# NUM_SCORES = 38

# Mixtral-8x7B
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/txt/"
# mixtral_prisma_amstar_rep: 38: 91, 39: 1 (156, extraction ok)
# RESULTS_FOLDER = "docs/prisma_amstar/mixtral8x7b_prisma_amstar/" # _rep
# NUM_SCORES = 38

# Claude-3-Opus
# FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/txt/"
# RESULTS_FOLDER = "docs/prisma_amstar/claude3_opus_prisma_amstar/" # _rep
# NUM_SCORES = 38

# Mixtral-8x22B
FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/txt/"
RESULTS_FOLDER = "docs/prisma_amstar/mixtral8x22b_prisma_amstar/" # _rep
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

### Extract ratings ("scores"), taking into account ranges for PRISMA (e.g. "P14-P23. [NA]", compare claude2_prisma_amstar/responses/109.txt.json)
def find_scores(llm_message):
    llm_scores = re.findall(r"\[(Yes|No|NA)\]", llm_message)
    ranges = re.findall(r"(P(\d*)-P(\d*)\.)(.*?)\[(Yes|No|NA)\]", llm_message.replace("\n", ""))
    if len(ranges):
        for range in ranges:
            # Add 10 to index to skip AMSTAR (ranges only observed for PRISMA)
            ind = 10 + int(range[1])
            llm_scores[ind:ind] = [llm_scores[ind]] * (int(range[2])-int(range[1]))
    return (llm_scores)

for response_file in response_files:
    id = int(response_file.split(".")[0])
    
    llm_message = open(responses_folder + response_file).read()
    if ".json" in response_file:
        response_json = json.loads(llm_message)
        # "choices" seems to be OpenAI's / OpenRouter's syntax
        if "choices" in response_json.keys():
            if "finish_reason" in response_json["choices"][0].keys() and not response_json["choices"][0]["finish_reason"] in ["stop", "stop_sequence", "eos", None]:
                print(f'{response_file}\nBad finish reason: {response_json["choices"][0]["finish_reason"]}')
                continue
            llm_message = response_json["choices"][0]["message"]["content"]
        # "content" seems to be Anthropic's syntax
        else:
            llm_message = response_json["content"][0]["text"]
    original_llm_message = llm_message
    
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

    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = llm_message.replace("[Yes,", "[<added-squared-brackets>[Yes]</added-squared-brackets>,")
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("phrase-after-yes-within-squared-brackets")

    if len(llm_scores) < NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub("Yes", "<added-squared-brackets>[Yes]</added-squared-brackets>", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-for-yes")

    # Same response twice in the same row => remove second
    if len(llm_scores) > NUM_SCORES:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"(.*)\[Yes\](.*)\[Yes\]", r"\1[Yes]\2", llm_message)
        llm_message = re.sub(r"(.*)\[No\](.*)\[No\]", r"\1[Yes]\2", llm_message)
        llm_message = re.sub(r"(.*)\[NA\](.*)\[NA\]", r"\1[Yes]\2", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("same-response-twice-in-a-row-(removed-second)")

    # Mixtral-8x22B sometimes reports some extra score brackets but correct ones are identified with "Response: " or "Answer: " prefix
    if len(llm_scores) > NUM_SCORES:
        llm_scores_with_prefix = [x[1] for x in re.findall(r"(Response: |Answer: |Verdict: )\"?\[(Yes|No|NA)\]", llm_message)]
        if len(llm_scores_with_prefix) == NUM_SCORES:
            llm_scores = llm_scores_with_prefix
            wrong_format.append("extra-score-brackets-without-prefix")

    # Mixtral-8x22B sometimes reports some extra score brackets but correct ones are identified with "- " prefix
    if len(llm_scores) > NUM_SCORES:
        llm_scores_with_prefix = [x[1] for x in re.findall(r"(- )\[(Yes|No|NA)\]", llm_message)]
        if len(llm_scores_with_prefix) == NUM_SCORES:
            llm_scores = llm_scores_with_prefix
            wrong_format.append("extra-score-brackets-without-prefix")

    # Mixtral-8x22B sometimes reports some extra score brackets but correct ones are identified with ": \"" prefix
    if len(llm_scores) > NUM_SCORES:
        llm_scores_with_prefix = [x[1] for x in re.findall(r"(: \")\[(Yes|No|NA)\]", llm_message)]
        if len(llm_scores_with_prefix) == NUM_SCORES:
            llm_scores = llm_scores_with_prefix
            wrong_format.append("extra-score-brackets-without-prefix")

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

    with open(FULLTEXT_FOLDER + response_file.replace(".json", "")) as f:
        fulltext = f.read()

    results.append({
        "publication_id": id,
        #"created": response_json["created"],
        "prompt_tokens": response_json["usage"]["prompt_tokens"] if 'response_json' in locals() and "usage" in response_json and 'prompt_tokens' in response_json["usage"] else int((len(prompt)+len(fulltext))/4),
        "completion_tokens": response_json["usage"]["completion_tokens"] if 'response_json' in locals() and "usage" in response_json  and 'completion_tokens' in response_json["usage"] else int(len(original_llm_message)/4),
        #"finish_reason": response_json["choices"][0]["finish_reason"],
        "wrong_format": wrong_format,
        "original_llm_scores_n": original_llm_scores_n,
        "final_llm_scores_n": final_llm_scores_n,
        "llm_scores": llm_scores,
        "llm_message": llm_message,
        "original_llm_message": original_llm_message,
    })

    # If PRISMA and AMSTAR are combined, split llm_message and compare quotes separately
    if NUM_SCORES == 38:
        llm_message_split = llm_message.split("P1.")
        if len(llm_message_split) == 1:
            llm_message_split = llm_message.split("P1:")
        if len(llm_message_split) == 1:
            llm_message_split = llm_message.split("P1\n")
        if len(llm_message_split) == 1:
            llm_message_split = llm_message.split("P1 -")
        if len(llm_message_split) > 2:
            print(f"{response_file}\More than 2 splits for 'P1' - Should be ok because of ''.join(llm_message_split[1:] below but double-check")
        quote_accuracy += [{"publication_id": id, "tool": "AMSTAR", **x} for x in compare_quotes(llm_message_split[0], fulltext, prompt)]
        quote_accuracy += [{"publication_id": id, "tool": "PRISMA", **x} for x in compare_quotes(''.join(llm_message_split[1:]), fulltext, prompt)]
    else:
        quote_accuracy += [{"publication_id": id, "tool": "PRISMA" if NUM_SCORES == 27 else "AMSTAR",  **x} for x in compare_quotes(llm_message, fulltext, prompt)]

results = pd.DataFrame(results).set_index("publication_id")
results.to_csv(RESULTS_FOLDER + "results.csv", na_rep="NA")
print(results["final_llm_scores_n"].value_counts())

quote_accuracy = pd.DataFrame(quote_accuracy)
quote_accuracy.to_csv(RESULTS_FOLDER + "quote_accuracy.csv", na_rep="NA", index=False)

results
#results[results["final_llm_scores_n"]>38]
# %%
