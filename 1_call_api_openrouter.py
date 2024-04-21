#%%
import os
#import openai
import json
import requests
from tqdm import tqdm
import numpy as np

FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/txt/"
#RESULTS_FOLDER = "docs/prisma_amstar/gpt4_prisma_amstar/"
#RESULTS_FOLDER = "docs/prisma_amstar/gpt4_prisma_amstar_rep/"
#RESULTS_FOLDER = "docs/prisma_amstar/claude2_prisma_amstar/"
#RESULTS_FOLDER = "docs/prisma_amstar/claude2_prisma_amstar_rep/"
#RESULTS_FOLDER = "docs/prisma_amstar/mixtral8x7b_prisma_amstar/"
#RESULTS_FOLDER = "docs/prisma_amstar/mixtral8x7b_prisma_amstar_rep/"
#RESULTS_FOLDER = "docs/prisma_amstar/mixtral8x22b_prisma_amstar/"
RESULTS_FOLDER = "docs/prisma_amstar/mixtral8x22b_prisma_amstar_rep/"

#FULLTEXT_FOLDER = "data/precis2/fulltext/pdf/txt/"
#RESULTS_FOLDER = "docs/precis2/gpt4_precis2/"
#RESULTS_FOLDER = "docs/precis2/gpt4_precis2_rep/"
#RESULTS_FOLDER = "docs/precis2/claude2_precis2/"
#RESULTS_FOLDER = "docs/precis2/claude2_precis2_rep/"
#RESULTS_FOLDER = "docs/precis2/mixtral8x7b_gpt4_prompt_precis2/"
#RESULTS_FOLDER = "docs/precis2/mixtral8x7b_precis2/"
#RESULTS_FOLDER = "docs/precis2/mixtral8x7b_precis2_rep/"
#RESULTS_FOLDER = "docs/precis2/mixtral8x22b_precis2/"
#RESULTS_FOLDER = "docs/precis2/mixtral8x22b_precis2_rep/"

#openai.api_base = "https://openrouter.ai/api/v1"
#openai.api_key = open("src/OPENROUTER_API_KEY").read()

API_KEY = open("src/hidden/API_KEY_OPENROUTER").read()

files = os.listdir(FULLTEXT_FOLDER)
files = list(filter(lambda x: (".txt" in x), files))
files.sort()

with open(RESULTS_FOLDER + "prompt_template/system.txt") as f:
    system_prompt = f.read()

files = np.array(files)[~np.isin([x + ".json" for x in files], np.array(os.listdir(RESULTS_FOLDER + "responses")))]

#%%
for fulltext_file in tqdm(files):
    fulltext_file = fulltext_file.lower()
    # Read publication full text
    with open(FULLTEXT_FOLDER + fulltext_file) as f:
        fulltext = f.read()

    # user_prompt has to be loaded in-loop because of string-replacement
    with open(RESULTS_FOLDER + "prompt_template/user.txt") as f:
        user_prompt = f.read()
    user_prompt = user_prompt.replace("%FULLTEXT%", fulltext)
    
    try:
        response = requests.post(
            url="https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {API_KEY}",
                "HTTP-Referer": "https://localhost/",
                "X-Title": f"{fulltext_file}",
            },
            data=json.dumps({
                "model": "mistralai/mixtral-8x22b-instruct",
                #"provider": {"order": ["Mistral"]},
                "messages": [
                    # For gpt4 and claude2:
                    #{"role": "system", "content": system_prompt},
                    #{"role": "user", "content": user_prompt}
                    # For mixtral:
                    {"role": "user", "content": system_prompt + user_prompt}
                ],
                "temperature": 0
            })
        )
        # response = openai.ChatCompletion.create(
        #     #model="openai/gpt-4-32k",
        #     #model="anthropic/claude-2",
        #     #model="mistralai/mixtral-8x7b-instruct",
        #     model="mistralai/mixtral-8x22b-instruct",
        #     messages=[
        #         # For gpt4 and claude2:
        #         #{"role": "system", "content": system_prompt},
        #         #{"role": "user", "content": user_prompt}
        #         # For mixtral:
        #         {"role": "user", "content": system_prompt + user_prompt}
        #     ],
        #     #provider={"order": ["Together"]},
        #     headers={"HTTP-Referer": "https://localhost/", "X-Title": fulltext_file},
        #     temperature=0,
        #     seed=42, # OpenAI models only apparently
        #     #max_tokens=10000,
        #     #stream=True
        # )
        # for stream=True
        # collected_messages = []
        # for chunk in response:
        #     chunk_message = chunk['choices'][0]['delta']["content"]
        #     collected_messages.append(chunk_message)
        #     print(chunk_message)
    except Exception as e:
        print(fulltext_file)
        print(e)
    else:
        with open(RESULTS_FOLDER + f"responses/{fulltext_file}.json", "a") as f:
            f.write(str(response.content.decode(response.encoding).strip()))
            # for stream=True
            #f.write(str("".join(collected_messages)))

# %%
