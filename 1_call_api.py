#%%
import os
import openai
from datetime import datetime
from tqdm import tqdm

experiment = "PRECIS-2/pragms_pragqol_59"
prompt_template = "Toolkit"

openai.api_key = open("src/API_KEY").read()

files = os.listdir(f"data/{experiment}/fulltext/")
files = list(filter(lambda x: (".txt" in x), files))
files.sort()

for fulltext_file in tqdm(files):
    fulltext_file = fulltext_file.lower()
    # Read publication full text
    with open(f"data/{experiment}/fulltext/{fulltext_file}") as f:
        fulltext = f.read()

    # Prepare system and user prompt
    with open(f"data/{experiment}/prompt_templates/{prompt_template}.system.txt") as f:
        system_prompt = f.read()
    with open(f"data/{experiment}/prompt_templates/{prompt_template}.user.txt") as f:
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
        with open(f"results/{experiment}/prompts/{datetime.now().strftime('%y-%m-%d_%H:%M:%S')} {fulltext_file} {prompt_template} response.json", "a") as f:
            f.write(str(response))

# %%
