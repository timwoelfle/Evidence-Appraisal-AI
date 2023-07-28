#%%
import re
import pandas as pd
from rapidfuzz import fuzz, process, utils

domain_names = ['Eligibility', 'Recruitment', 'Setting', 'Organization', 'Flexibility (delivery)', 'Flexibility (adherence)', 'Follow-up', 'Primary outcome', 'Primary analysis']

def split_domains(gpt_message):
    domain_name_ind = 0

    gpt_message = gpt_message.splitlines()
    for i in range(len(gpt_message)):
        if fuzz.partial_ratio(gpt_message[i][:50], domain_names[domain_name_ind], processor=utils.default_process) > 90:
            gpt_message[i] = "~~~~~" + gpt_message[i]
            domain_name_ind += 1
            if domain_name_ind == 9:
                break
    gpt_message = "\n".join(gpt_message)

    domains = gpt_message.split("~~~~~")[1:]
    domains = {domain_names[i]: domains[i] for i in range(len(domains))}

    return domains

def get_score(domain):
    domain_scores = re.findall(r"Score: \[?(\d|NA)\]", domain)
    if not len(domain_scores):
        domain_scores = re.findall(r"\[(\d|NA)\]", domain)
    if not len(domain_scores):
        domain_scores = [x.replace("Not applicable", "NA") for x in re.findall("Not applicable", domain)]
    return domain_scores

def extract_quotes(gpt_message):
    # Sometimes there is a summary paragraph at the bottom, remove it with [0:9]
    domains = split_domains(gpt_message)[0:9]
    quotes = {}
    for domain in domains:
        domain_name = process.extractOne(domain, domain_names, scorer=fuzz.partial_ratio)[0]
        quotes[domain_name] = re.findall(r'"(.*)"', domain)
    return quotes

# %%
if __name__ == "__main__":
    results = pd.read_csv("../results/PRECIS-2/random_subset_50/23-07-10_results_2Toolkit.csv", index_col="pragmeta_trial_id")
    gpt_message = results.loc[697, "gpt_message"]
    print(get_domain_names(split_domains(gpt_message)))
    #quotes = extract_quotes(gpt_message)
    #print(quotes)

# %%
