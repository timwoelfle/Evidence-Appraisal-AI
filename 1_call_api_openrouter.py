#%%
import os
import openai
from tqdm import tqdm

FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/txt/"
RESULTS_FOLDER = "docs/prisma_amstar/gpt4_prisma_amstar_rep/"
#RESULTS_FOLDER = "docs/prisma_amstar/claude2_prisma_amstar/"

# FULLTEXT_FOLDER = "data/precis2/fulltext/pdf/txt/"
# RESULTS_FOLDER = "docs/precis2/gpt4_precis2/"
#RESULTS_FOLDER = "docs/precis2/claude2_precis2_rep/"

openai.api_base = "https://openrouter.ai/api/v1"
openai.api_key = open("src/OPENROUTER_API_KEY").read()

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
            model="openai/gpt-4-32k",
            #model="anthropic/claude-2",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            headers={"HTTP-Referer": "https://localhost/", "X-Title": fulltext_file},
            temperature=0,
            max_tokens=8000,
            #stream=True
        )
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
            f.write(str(response))
            #f.write(str("".join(collected_messages)))

# %%
