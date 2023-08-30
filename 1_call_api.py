#%%
import os
import openai
from tqdm import tqdm

#FULLTEXT_FOLDER = "data/PRISMA-AMSTAR/cullis2017/fulltext/txt/"
#RESULTS_FOLDER = "results/PRISMA-AMSTAR/cullis2017_amstar_gpt3.5_rep/"
FULLTEXT_FOLDER = "data/PRECIS-2/pragms-pragqol-56/fulltext/txt/"
RESULTS_FOLDER = "results/PRECIS-2/pragms-pragqol-56_toolkit_gpt3.5_rep/"

openai.api_key = open("src/API_KEY").read()

files = os.listdir(FULLTEXT_FOLDER)
files = list(filter(lambda x: (".txt" in x), files))
files.sort()

#%%
for fulltext_file in tqdm(files):
    fulltext_file = fulltext_file.lower()
    # Read publication full text
    with open(FULLTEXT_FOLDER + fulltext_file) as f:
        fulltext = f.read()

    # Prepare system and user prompt
    with open(RESULTS_FOLDER + "prompt_template/system.txt") as f:
        system_prompt = f.read()
    with open(RESULTS_FOLDER + "prompt_template/user.txt") as f:
        user_prompt = f.read()

    user_prompt = user_prompt.replace("%FULLTEXT%", fulltext)

    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo-16k-0613",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0,
            max_tokens=2000
        )
    except Exception as e:
        print(fulltext_file)
        print(e)
    else:
        with open(RESULTS_FOLDER + f"responses/{fulltext_file}.json", "a") as f:
            f.write(str(response))

# %%
