---
name: word-log-summary
description: Summarize dictionary_recoder logs into a deduplicated word list. Use when asked to generate or refresh word_list.tsv from word_lookup_log.tsv with lemmatization, 30s duplicate suppression, and contextual notes. Triggers (JP): 単語リスト作って/単語帳作って/word_list.tsv更新.
---

# Word Log Summary Skill

This skill regenerates `word_list.tsv` from `word_lookup_log.tsv` using Codex reasoning (no external NLP libraries). Use it whenever the user asks to create or refresh the vocab list.

## Inputs / outputs
- Input: `word_lookup_log.tsv` (header: timestamp, term, title, url)
- Output: `word_list.tsv` (columns: word, description_en, context, count)

## Rules to apply (Codex does the work)
1) Lemmatize each term to its base form (use your own linguistic judgment).
2) Count occurrences while ignoring repeats within 30 seconds of the previous occurrence of the same lemma.
3) Keep the most recent title as the context anchor per lemma.
4) Fill `description_en` with a concise dictionary-like English definition.
5) Fill `context` in Japanese: explain how the word is used in that paper.
   - Use the URL to fetch/skim the paper when possible.
   - Search within the page for the term; if the exact sentence is not findable, infer from nearby context or the paper’s topic.
   - If the URL is inaccessible, fall back to the title and general domain knowledge.

## Workflow when triggered
1) Read `word_lookup_log.tsv` and parse valid rows.
2) Build a lemma map (raw term -> lemma) using Codex judgment.
3) Apply the 30s suppression rule and compute counts per lemma.
4) For each lemma, use the URL to derive a concrete, Japanese context note.
5) Write `word_list.tsv` with the required columns and counts.
6) Show a short preview if the user asks.

## Mandatory validation (to avoid count/omission errors)
- Create a small “evidence list” per lemma: include the timestamps that were counted and which were ignored due to the 30s rule.
- Confirm every raw term from the log appears in the lemma map (no omissions).
- Verify that each lemma count matches the number of counted timestamps.
- If any ambiguity exists, ask the user before finalizing `word_list.tsv`.

## Editing or extending
- If the user wants richer context, prioritize visiting the URL and summarizing the local usage.
- If a lemma is unclear, ask a short clarification or show the row that needs review.

## Safety/notes
- This workflow is manual and Codex-driven; no scripts are required.
