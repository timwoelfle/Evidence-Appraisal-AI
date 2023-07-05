#%%
import os
import openai
from datetime import datetime
from tqdm import tqdm

openai.api_key = open("src/API_KEY").read()

files = os.listdir("data/fulltext/")
files = list(filter(lambda x: (".txt" in x), files))
files.sort()

for fulltext_file in files:
    fulltext_file = fulltext_file.lower()
    print(fulltext_file)
    # Read publication full text
    with open("data/fulltext/" + fulltext_file) as f:
        fulltext = f.read()

    # Prepare system and user prompt
    prompt_template = "2Toolkit"
    with open("data/prompt_templates/" + prompt_template + ".system.txt") as f:
        system_prompt = f.read()
    with open("data/prompt_templates/" + prompt_template + ".user.txt") as f:
        user_prompt = f.read()

    user_prompt = user_prompt.replace("%FULLTEXT%", fulltext)

    with open(f"results/prompts/{datetime.now().strftime('%y-%m-%d_%H:%M:%S')} {fulltext_file} {prompt_template}.system.txt", "a") as f:
        f.write(system_prompt)

    with open(f"results/prompts/{datetime.now().strftime('%y-%m-%d_%H:%M:%S')} {fulltext_file} {prompt_template}.user.txt", "a") as f:
        f.write(user_prompt)

    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo-16k-0613",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        temperature=0,
        max_tokens=2000
    )

    with open(f"results/prompts/{datetime.now().strftime('%y-%m-%d_%H:%M:%S')} {fulltext_file} {prompt_template} response.json", "a") as f:
        f.write(str(response))

# %%
