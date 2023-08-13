#%%
import re
from rapidfuzz import distance, utils
import parasail
#%%
# Extract scores

def extract_prisma_amstar(llm_message, num_scores):
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

    if len(llm_scores) < num_scores:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"\[(Partial Yes|Partial|Partially|Adequate)\]", r"[\1 <added>[Yes]</added>]", llm_message)
        llm_message = re.sub(r"\[(Inadequate)\]", r"[\1 <added>[No]</added>]", llm_message)
        llm_message = re.sub(r"\[(Unclear|Insufficient information|It is unclear|Yes/No)\]", r"[\1 <added>[NA]</added>]", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("wrong-response-partial-unclear-etc")
    
    if len(llm_scores) < num_scores:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"([A|P]\d+. )Yes(?!\w)(?!.*\[Yes\])", r"\1<added-squared-brackets>[Yes]</added-squared-brackets>", llm_message)
        llm_message = re.sub(r"([A|P]\d+. )No(?!\w)(?!.*\[No\])", r"\1<added-squared-brackets>[No]</added-squared-brackets>", llm_message)
        llm_message = re.sub(r"([A|P]\d+. )NA(?!\w)(?!.*\[NA\])", r"\1<added-squared-brackets>[NA]</added-squared-brackets>", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-in-numbered-list")
    
    if len(llm_scores) < num_scores:
        len_pre = len(llm_scores)
        llm_message = re.sub("(?<!\w)NA(?!\w)(?!.*\[NA\])", "<added-squared-brackets>[NA]</added-squared-brackets>", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-for-na")

    if len(llm_scores) < num_scores:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"Not applicable(?!.*\[NA\])", "Not applicable <added>[NA]</added>", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("not-applicable-missing-na-in-squared-brackets")
    
    if len(llm_scores) < num_scores:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"\n- Yes(?!\w)(?!.*\[Yes\])(?=.*\n\n|.*$)", r"\n- <added-squared-brackets>[Yes]</added-squared-brackets>", llm_message)
        llm_message = re.sub(r"\n- No(?!\w)(?!.*\[No\])(?=.*\n\n|.*$)", r"\n- <added-squared-brackets>[No]</added-squared-brackets>", llm_message)
        llm_message = re.sub(r"\n- NA(?!\w)(?!.*\[NA\])(?=.*\n\n|.*$)", r"\n- <added-squared-brackets>[NA]</added-squared-brackets>", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-in-unnumbered-list")

    if len(llm_scores) < num_scores:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"\n- (Partial Yes|Partial|Partially|Adequate)(?!\w)(?!.*\[Yes\])", r"\n- \1 <added>[Yes]</added>", llm_message)
        llm_message = re.sub(r"\n- (Inadequate)(?!\w)(?!.*\[No\])", r"\n- \1 <added>[No]</added>", llm_message)
        llm_message = re.sub(r"\n- (Unclear|Insufficient information|It is unclear|Yes/No)(?!\w)(?!.*\[NA\])", r"\n- \1 <added>[NA]</added>", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("wrong-response-partial-unclear-etc-without-squared-brackets")

    if len(llm_scores) < num_scores:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"(Yes|No|NA) *\n", r"<added-squared-brackets>[\1]</added-squared-brackets>\n", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-end-of-line")
    
    if len(llm_scores) < num_scores:
        len_pre = len(llm_scores)
        llm_message = re.sub(r"(Yes|No|NA) -", r"<added-squared-brackets>[\1]</added-squared-brackets> -", llm_message)
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-pre-dash")
    
    # Apparently not needed anymore as of 23-08-13
    # if len(llm_scores) < num_scores:
    #     len_pre = len(llm_scores)
    #     llm_message = re.sub(r"\"(Yes|No|NA)\"", r"\"<added-squared-brackets>[\1]</added-squared-brackets>\"", llm_message)
    #     llm_scores = find_scores(llm_message)
    #     if len(llm_scores) > len_pre:
    #         wrong_format.append("missing-squared-brackets-instead-quotes")

    # if len(llm_scores) < num_scores:
    #     len_pre = len(llm_scores)
    #     llm_message = llm_message.replace("Not reported", "Not reported <added>[No]</added>")
    #     llm_scores = find_scores(llm_message)
    #     if len(llm_scores) > len_pre:
    #         wrong_format.append("not-reported-instead-of-no")

    if len(llm_scores) < num_scores:
        len_pre = len(llm_scores)
        llm_message = llm_message.replace("N/A", "N/A <added>[NA]</added>")
        llm_scores = find_scores(llm_message)
        if len(llm_scores) > len_pre:
            wrong_format.append("missing-squared-brackets-na-with-slash")

    # Same response twice in the same row => remove second
    if len(llm_scores) > num_scores:
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
    if len(llm_scores) > num_scores:
        llm_scores = llm_scores[0:num_scores]
    
    code = {"Yes": 1, "No": 0, "NA": "NA"}
    llm_scores = [code[x] for x in llm_scores]
    return (wrong_format, original_llm_scores_n, final_llm_scores_n, llm_scores, llm_message)

# Extract quotes

def extract_quotes(llm_message):
    quotes = re.findall(r'"(.*)"', llm_message)
    return [x for x in quotes if x not in ["[Yes]", "[No]", "[NA]"]]

def compare_quote(quote, fulltext):
    if utils.default_process(fulltext).find(utils.default_process(quote)) != -1:
        best_match = quote
        similarity = 100
    else:
        # Directly using fuzz.partial_ratio_alignment often cuts reference strings short, also doesn't allow custom weight
        # Workaround: use parasail with Smith Waterman to identify best_match first
        # (Compare: https://github.com/maxbachmann/RapidFuzz/issues/323)
        ssw = parasail.ssw(utils.default_process(quote).encode("latin-1", "ignore"), utils.default_process(fulltext).encode("latin-1", "ignore"), 10, 1, parasail.blosum50)
        best_match = fulltext[ssw.ref_begin1:ssw.ref_end1+1]
        similarity = distance.Levenshtein.normalized_similarity(best_match, quote, weights=[1,0.5,1.5])*100

    return (best_match, similarity)

def compare_quotes(llm_message, fulltext, prompt):
    quotes = extract_quotes(llm_message)
    quote_accuracy = []
    for quote in quotes:
        (fulltext_best_match, fulltext_similarity) = compare_quote(quote, fulltext)
        (prompt_best_match, prompt_similarity) = compare_quote(quote, prompt)
        if fulltext_similarity > prompt_similarity:
            quote_accuracy.append({
                "quote": quote,
                "best_match_source": "fulltext",
                "best_match": fulltext_best_match,
                "similarity": fulltext_similarity
            })
        else:
            quote_accuracy.append({
                "quote": quote,
                "best_match_source": "prompt",
                "best_match": prompt_best_match,
                "similarity": prompt_similarity
            })
    return (quote_accuracy)

# %%
