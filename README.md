# Benchmarking Human-AI Collaboration for Common Evidence Appraisal Tools

Tim Woelfle, Julian Hirt, Perrine Janiaud, Ludwig Kappos, John P. A. Ioannidis, Lars G. Hemkens

## Abstract

Background: It is unknown whether large language models (LLMs) may facilitate time- and resource-intensive text-related processes in evidence appraisal.
Objectives: To quantify the agreement of LLMs with human consensus in appraisal of scientific reporting (PRISMA) and methodological rigor (AMSTAR) of systematic reviews and design of clinical trials (PRECIS-2). To identify areas, where human-AI collaboration would outperform the traditional consensus process of human raters in efficiency.
Design: Five LLMs (Claude-3-Opus, Claude-2, GPT-4, GPT-3.5, Mixtral) assessed 112 systematic reviews applying the PRISMA and AMSTAR criteria, and 56 randomized controlled trials applying PRECIS-2. We quantified agreement between human consensus and (1) individual human raters; (2) individual LLMs; (3) combined LLMs approach; (4) human-AI collaboration. Ratings were marked as deferred (undecided) in case of inconsistency between combined LLMs or between the human rater and the LLM.
Results: Individual human rater accuracy was 89% for PRISMA and AMSTAR, and 75% for PRECIS-2. Individual LLM accuracy was ranging from 57% (Mixtral) to 70% (Claude-3-Opus) for PRISMA, 50% (Mixtral) to 74% (Claude-3-Opus) for AMSTAR, and 38% (GPT-4) to 58% (Mixtral) for PRECIS-2. Combined LLM ratings led to accuracies of 75-87% for PRISMA (3-80% deferred), 71-88% for AMSTAR (7-88% deferred), and 60-79% for PRECIS-2 (7-92% deferred). Human-AI collaboration resulted in the best accuracies from 89-96% for PRISMA (25-44% deferred), 91-96% for AMSTAR (27-52% deferred), and 80-86% for PRECIS-2 (67-75% deferred).
Conclusions: Current LLMs alone appraised evidence worse than humans. Human-AI collaboration may reduce workload for the second human rater for the assessment of reporting (PRISMA) and methodological rigor (AMSTAR) but not for complex tasks such as PRECIS-2.

## Contributions

Contributions and extensions (e.g. new LLMs or new evidence appraisal tools) are very welcome! However, please do get in touch before starting a project for better alignment.

Structure:
- `data` contains human ratings and human consensus for each tool as well as all full text files.
- `docs` contains all LLM results and overviews and is called `docs` only for GitHub Pages to route directly to it.
- `src` contains dependencies.

Adding new LLM experiments for a TOOL (e.g. precis2) generally goes like this:
1. Create fulltext folders, e.g. `data/TOOL/fulltext/pdf/txt/` (containing all plain full texts as ID.txt, e.g. `data/precis2/fulltext/pdf/648.txt`) or `data/TOOL/fulltext/pdf/png/` (containing a subfolder for every ID with a png for each page named `ID_PAGENUM.png`, e.g. `data/precis2/fulltext/pdf/png/648/648_1.png` etc.).
2. Create experiment subfolder in `docs/TOOL/` with subfolders `prompt_template`, `responses`, and `results`. Add new experiment to `docs/TOOL/params.json`.
3. Adjust and run `1_call_api_API.py`.
4. Adjust and run `2_extract_results_TOOL.py`.
5. Adjust and run `3_render_dashboards.r` for the respective TOOL / experiment.
6. Adjust and render `docs/index.rmd`.
