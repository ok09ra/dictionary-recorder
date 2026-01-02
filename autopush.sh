#!/bin/zsh
set -eu

SCRIPT_DIR="$(cd -- "$(dirname "${0:A}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/config.env}"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

export PATH="${AUTOPUSH_PATH:-/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin}"

REPO="${REPO_DIR:-$SCRIPT_DIR}"
LOG="${AUTOPUSH_AGENT_LOG:-$REPO/autopush.agent.log}"

# 二重起動防止
LOCKDIR="${AUTOPUSH_LOCK_DIR:-/tmp/dictionary_recoder_autopush.lock}"
if ! mkdir "$LOCKDIR" 2>/dev/null; then exit 0; fi
trap 'rmdir "$LOCKDIR"' EXIT

log(){ print -r -- "$(date '+%F %T') | $*" >> "$LOG"; }

# 対話プロンプト禁止（ハング防止）
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=/usr/bin/false
export SSH_ASKPASS=/usr/bin/false
export GIT_SSH_COMMAND="ssh -4 -o BatchMode=yes -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2"

log "START pid=$$ whoami=$(whoami)"

cd "$REPO"

# fetch（30秒で切る）
log "fetch origin..."
perl -e 'alarm 30; exec @ARGV' -- git fetch -v origin 2>&1 | sed 's/^/  /' >> "$LOG"
log "fetch done (exit=$?)"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
log "branch=$BRANCH"

# 先にrebaseして non-fast-forward を回避（60秒で切る）
log "pull --rebase origin $BRANCH..."
perl -e 'alarm 60; exec @ARGV' -- git pull --rebase origin "$BRANCH" 2>&1 | sed 's/^/  /' >> "$LOG" || {
  log "rebase failed -> abort"
  git rebase --abort 2>&1 | sed 's/^/  /' >> "$LOG" || true
  exit 1
}
log "rebase done"

# 変更がなければ終了
if git diff --quiet && git diff --cached --quiet; then
  log "NO_CHANGES exit=0"
  exit 0
fi

log "git add -A"
git add -A

log "commit..."
git commit -m "dairy commit $(date '+%F %T')" 2>&1 | sed 's/^/  /' >> "$LOG" || true

# push（60秒で切る）
log "push origin $BRANCH..."
perl -e 'alarm 60; exec @ARGV' -- git push origin "$BRANCH" 2>&1 | sed 's/^/  /' >> "$LOG"
log "push done (exit=$?)"

log "DONE"
exit 0
