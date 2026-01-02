# Dictionary Recoder

When you read papers and hit unfamiliar terms, you want a quick vocab log. This kit gives you a force-click shortcut to append those words (with page title/URL) into a TSV, and a daily git autopush so the log stays backed up.

## What this does
- BetterTouchTool action copies the current selection, grabs the active tab title/URL from Vivaldi, and appends a TSV row (`timestamp<TAB>term<TAB>title<TAB>url`) to `word_lookup_log.tsv` with file locking.
- `config.env` centralizes paths (log location, repo, LaunchAgent name, PATH, schedule).
- `autopush.sh` does `git pull --rebase`, commit, and push.
- `autopush_launchagent.sh` generates/loads a LaunchAgent plist that runs `autopush.sh` daily.

## Requirements
- macOS
- BetterTouchTool (for the trigger in `exported_triggers.bttpreset`)
- Git with access to the repo remote
- Python 3 (for file locking in the AppleScript snippet)
- Zsh (for the shell scripts; default on macOS)

## BetterTouchTool install & trigger
- Install BetterTouchTool from https://folivora.ai/ (drag to Applications).
- Open BTT and grant required macOS permissions (Accessibility/Input Monitoring when prompted).
- In BTT, import `exported_triggers.bttpreset`.
- The preset binds a trackpad force click (anywhere) to run the AppleScript that logs the current selection. You can change the trigger inside BTT to your preferred gesture or shortcut.

## Setup
1) Clone this repo.
   ```sh
   # Open Terminal (Spotlight → type "Terminal" → Enter), then:
   git clone https://github.com/yourname/dictionary_recoder.git
   cd dictionary_recoder
   ```
2) Copy and edit `config.env` to match your environment:
   - `REPO_DIR`: where this repo lives.
   - `WORD_LOOKUP_LOG`: where to write the TSV.
   - `LAUNCH_AGENT_LABEL`, `LAUNCH_START_HOUR`, `LAUNCH_START_MINUTE`: name/time for the LaunchAgent.
   - `AUTOPUSH_PATH`: PATH to use for git inside the LaunchAgent.
   ```sh
   cp config.env config.env.local  # optional backup
   open -e config.env              # opens TextEdit for easy editing
   ```
3) Import `exported_triggers.bttpreset` into BetterTouchTool.
   - The AppleScript reads `config.env` (default `${HOME}/Documents/dictionary_recoder/config.env`) and uses `WORD_LOOKUP_LOG`.
   - The preset will create the TSV (with header) if missing.
4) Load the LaunchAgent:
   - `cd` into the repo.
   - Run `./autopush_launchagent.sh` to generate the plist and (re)load it via `launchctl`.
   - This schedules a daily autopush at the hour/minute you set in `config.env`.

## Step-by-step (all commands)
For users who prefer exact commands (e.g., non-technical/biology folks):
1) Open Terminal (Spotlight → type “Terminal” → Enter).
2) Run:
   ```sh
   git clone https://github.com/yourname/dictionary_recoder.git
   cd dictionary_recoder
   cp config.env config.env.local  # keep a backup
   open -e config.env              # edit paths; save & close
   ./autopush_launchagent.sh       # install/refresh LaunchAgent
   ```
3) Double-click `exported_triggers.bttpreset` (or import via BTT preferences) and allow permissions.
4) In BTT, ensure the force-click trigger exists (Touchpad → “Force Click Anywhere”). Change it if you like.
5) Test: select a word in any app, force click. Open `word_lookup_log.tsv` to confirm a new row.

## Usage
- In BetterTouchTool, force click (default preset) while text is selected in the frontmost app. If Vivaldi is frontmost, page title/URL are captured; otherwise they are blank.
- The TSV is appended atomically with a `.lock` file to avoid races.
- Autopush runs daily via LaunchAgent: pull --rebase, commit any changes, push to the current branch.

## Customization
- Change the LaunchAgent label/time/paths in `config.env`, then rerun `./autopush_launchagent.sh`.
- To disable autopush: `launchctl bootout gui/$(id -u) "$LAUNCH_AGENT_PATH"` (uses values from `config.env`).
- You can run `autopush.sh` manually anytime; it will exit quickly if no changes exist.

## Files of interest
- `config.env` — central config for paths, logs, LaunchAgent.
- `exported_triggers.bttpreset` — BetterTouchTool preset containing the AppleScript action.
- `autopush.sh` — git pull/commit/push helper.
- `autopush_launchagent.sh` — builds/loads the LaunchAgent plist for `autopush.sh`.
- `word_lookup_log.tsv` — the generated TSV log (header added automatically).
- `word_list.tsv` — summarized vocab list (base form + counts + context).
- `skills/word-log-summary/` — Codex skill instructions to regenerate `word_list.tsv`.

## Regenerate the vocab list (word_list.tsv)
This repo uses Codex to read the log and regenerate the vocab list (no scripts or NLP libraries required).

Example prompt to Codex:
```
Use the word-log-summary skill. Please read word_lookup_log.tsv and regenerate word_list.tsv.
Rules: lemmatize to base forms, ignore repeats within 30 seconds for the same lemma,
fill description_en with concise English meanings, and write context in Japanese based
on the paper URL/title (use the URL when possible).
```
