#%%
import re
from rapidfuzz import distance
import parasail

# Extract quotes

def extract_unique_quotes(llm_message):
    quotes = list(set(re.findall(r'"([^"\r\n]+)"', llm_message)))
    return [x for x in quotes if x not in ["[Yes]", "[No]", "[NA]"]]

# Sometimes quotes are interrupted by a gap (...), make sure to exclude that gap from quote
def split_interrupted_quotes(llm_message):
    quotes = extract_unique_quotes(llm_message)
    quotes_split = [[quot.strip() for quot in quote.split("...")] for quote in quotes]
    replacements = ['" [...] "'.join(quote) for quote in quotes_split]
    for i in range(len(quotes)):
        llm_message = llm_message.replace(quotes[i], replacements[i])
    return llm_message

# Adapted from default_process() from https://github.com/maxbachmann/RapidFuzz/blob/main/src/rapidfuzz/utils_py.py
def default_process_wo_strip(sentence):
    _alnum_regex = re.compile(r"(?ui)\W")
    string_out = _alnum_regex.sub(" ", sentence)
    return string_out.lower()

def compare_quote(quote, fulltext):
    if default_process_wo_strip(fulltext).find(default_process_wo_strip(quote)) != -1:
        best_match = quote
        similarity = 100
    else:
        # Directly using fuzz.partial_ratio_alignment often cuts reference strings short, also doesn't allow custom weight
        # Workaround: use parasail with Smith Waterman to identify best_match first
        # (Compare: https://github.com/maxbachmann/RapidFuzz/issues/323)
        processed_quote = default_process_wo_strip(quote)
        ssw = parasail.ssw(processed_quote.encode("latin-1", "ignore"), default_process_wo_strip(fulltext).encode("latin-1", "ignore"), 10, 1, parasail.blosum50)
        # Replace newline with space, except hyphenization at the end of line; reduce multiple spaces to a single one
        best_match = re.sub(" +", " ", fulltext[ssw.ref_begin1:ssw.ref_end1+1].replace("-\n", "").replace("\n", " "))
        similarity = distance.Levenshtein.normalized_similarity(default_process_wo_strip(best_match), processed_quote, weights=[1,0.5,1.5])*100

    return (best_match, similarity)

def compare_quotes(llm_message, fulltext, prompt):
    quotes = extract_unique_quotes(llm_message)
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
