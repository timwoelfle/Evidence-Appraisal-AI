#%%
import os
#import requests
#import json
import base64
from tqdm import tqdm
import anthropic

#FULLTEXT_FOLDER = "data/prisma_amstar/fulltext/pdf/png/"
#RESULTS_FOLDER = "docs/prisma_amstar/claude3_opus_prisma_amstar_rep/"
FULLTEXT_FOLDER = "data/precis2/fulltext/pdf/png/"
RESULTS_FOLDER = "docs/precis2/claude3_opus_precis2_rep/"

API_KEY = open("src/hidden/API_KEY_ANTHROPIC").read()

papers = os.listdir(FULLTEXT_FOLDER)
papers.sort()

client = anthropic.Anthropic(
    # defaults to os.environ.get("ANTHROPIC_API_KEY")
    api_key=API_KEY,
)

# Prepare system and user prompt (can be outside of loop as no replacement in user_prompt happens)
with open(RESULTS_FOLDER + "prompt_template/system.txt") as f:
    system_prompt = f.read()
with open(RESULTS_FOLDER + "prompt_template/user.txt") as f:
    user_prompt = f.read()
#%%
for paper in tqdm(papers):
    images = os.listdir(FULLTEXT_FOLDER + paper)
    images = list(filter(lambda x: (".png" in x), images))
    # Sort files naturally like in file explorer (i.e. '101_2.png' comes before '101_10.png', unlike .sort())
    # First runs of claude3_opus_prisma_amstar and claude3_opus_precis2 were with raw .sort(), i.e. scrambled pages!
    images.sort(key=lambda x: int(''.join(filter(str.isdigit, x))))

    images_data = []
    for image in images:
        with open(f"{FULLTEXT_FOLDER}{paper}/{image}", "rb") as image_file:
            images_data.append( base64.b64encode(image_file.read()).decode('utf-8'))

    try:
        user = {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "The full text to be assessed is attached as one image per page."
                },
                *[
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": "image/png",
                            "data": image_data
                        }
                    }
                    for image_data in images_data
                ],
                {
                    "type": "text",
                    "text": user_prompt
                }
            ]
        }
        
        message = client.messages.create(
            model="claude-3-opus-20240229",
            max_tokens=4096,
            temperature=0.0,
            system=system_prompt,
            messages=[user],
        )   

        # OpenRouter's 4MB request-size limit prohibits its use for this project's images as of 2024-04
        # response = requests.post(
        #     url="https://openrouter.ai/api/v1/chat/completions",
        #     headers={ 
        #         "Authorization": f"Bearer {API_KEY}",
        #         "HTTP-Referer": "https://localhost/",
        #         "X-Title": paper,
        #     },
        #     data=json.dumps({
        #         "model": "anthropic/claude-3-opus", #"openai/gpt-4-vision-preview",
        #         "messages": [
        #             {
        #                 "role": "system",
        #                 "content": system_prompt
        #             },
        #             user
        #         ],
        #         "temperature": 0,
        #         "seed": 42,
        #     })
        # )
    except Exception as e:
        print(paper)
        print(e)
    else:
        with open(RESULTS_FOLDER + f"responses/{paper}.txt.json", "a") as f:
            f.write(str(message.json()))

# %%
