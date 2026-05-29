# =================================================
# Shell Environment & Language Tools
# =================================================

# --- Ruby ---
eval "$(rbenv init - zsh)"

# --- Editor (Neovim を優先) ---
export VISUAL=nvim
export EDITOR=nvim

# --- Node / npm / pnpm ---
export PATH=$(npm prefix -g)/bin:$PATH
export PATH="/usr/local/lib/node_modules/shadcn-ui/bin:$PATH"
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# --- nvm (Node Version Manager) ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# --- Bun ---
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --- Database CLI (MySQL / PostgreSQL) ---
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# --- Flutter ---
export PATH="$HOME/development/flutter/bin:$PATH"

# --- Java ---
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
export PATH="$JAVA_HOME/bin:$PATH"
export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include"

# --- Rust / Cargo ---
source "$HOME/.cargo/env"

# --- Antigravity ---
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"


# =================================================
# CLI Tools & Plugins
# =================================================

# --- Sheldon (Plugin Manager) ---
eval "$(sheldon source)"

# --- Zeno (Completion / Snippets) ---
export ZENO_HOME=~/.config/zeno
if [[ -n $ZENO_LOADED ]]; then
  bindkey '^i' zeno-completion
  bindkey ' '  zeno-auto-snippet
  bindkey '^m' zeno-auto-snippet-and-accept-line
  bindkey '^r' zeno-smart-history-selection
fi

# --- Starship (Prompt) ---
eval "$(starship init zsh)"


# =================================================
# Aliases
# =================================================

# --- ディレクトリ移動 ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# --- ファイル一覧 ---
alias ll='ls -lah'
alias la='ls -a'
alias lt='ls -lahtr'                               # 更新日時順(最新が下)

# --- エディタ ---
alias v='nvim'
alias vi='nvim'

# --- Python ---
alias python='python3'
alias pip='pip3'

# --- 汎用ショートカット ---
alias c='clear'
alias h='history | tail -30'
alias mk='mkdir -p'                                # 深い階層も一発作成
alias ports='lsof -i -P -n | grep LISTEN'          # 使用中のポート確認

# --- Git ---
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gsb='git submodule'

# --- Dotfiles 管理 ---
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# --- Docker Compose ---
alias dc='docker compose'
alias dcu='docker compose up'
alias dcud='docker compose up -d'                  # バックグラウンド起動
alias dcd='docker compose down'
alias dcb='docker compose build'
alias dcl='docker compose logs -f'                 # ログ追跡

# --- Rails 開発コマンド (web サービス前提) ---
alias dcr='docker compose run --rm web bundle exec'
alias dcrails='docker compose run --rm web bundle exec rails'
alias dcrake='docker compose run --rm web bundle exec rake'
alias dcsh='docker compose exec web bash'          # 起動中の web コンテナに入る

# --- 個別プロジェクトの DB 接続 ---
alias ecdb='docker exec -it ec_training_db psql -U ecuser -d ecdb'

# --- cmux ブラウザブックマーク ---
alias c-yt='cmux browser open "https://www.youtube.com/"'
alias c-gh='cmux browser open "https://github.com/"'
alias c-qi='cmux browser open "https://qiita.com/"'
alias c-aws='cmux browser open "https://console.aws.amazon.com/"'
alias c-ver='cmux browser open "https://vercel.com/dashboard"'
alias c-gem='cmux browser open "https://gemini.google.com/"'


# =================================================
# Custom Functions
# =================================================

# --- nba: Add a note with article title and URL ---
function nba() {
  if [ $# -lt 1 ]; then
    echo "Usage: nba <url>           # Auto-fetch title"
    echo "       nba <title> <url>   # Manual title"
    return 1
  fi

  local title=""
  local url=""

  if [ $# -eq 1 ]; then
    url="$1"
    echo "Fetching title from: $url"
    title=$(curl -sL --max-redirs 3 --max-time 5 --compressed "$url" | head -c 512 | perl -0777 -ne 'print $1 if /<title[^>]*>([^<]+)<\/title>/i')
    title=$(echo "$title" | perl -pe 's/^\s+|\s+$//g; s/\s+/ /g')
    if [ -z "$title" ]; then
      echo "Error: Could not fetch title from URL"
      return 1
    fi
    echo "Title: $title"
  else
    title="$1"
    url="$2"
  fi

  local content="# ${title}

参照: [${title}](${url})"

  nb add --filename "${title}.md" --content "$content"
  echo "Note created: [${title}](${url})"
}

# --- nbq: Search notes and select with fzf preview ---
function nbq() {
  if [ -z "$1" ]; then
    echo "Usage: nbq <search query>"
    return 1
  fi

  local query="$*"
  local results=$(nb q "$query" --no-color 2>/dev/null | grep -E '^\[[0-9]+\]')

  if [ -z "$results" ]; then
    echo "No results found for: $query"
    return 1
  fi

  export _NBQ_QUERY="$query"

  local selected=$(echo "$results" | fzf --ansi \
    --preview 'note_id=$(echo {} | sed -E "s/^\[([0-9]+)\].*/\1/")
               echo "=== Note [$note_id] ==="
               echo ""
               nb show "$note_id" | head -5
               echo ""
               echo "=== Matching lines ==="
               echo ""
               nb show "$note_id" | grep -i --color=always -C 2 "$_NBQ_QUERY" | head -30' \
    --preview-window=right:60%:wrap \
    --header "Search: $query")

  unset _NBQ_QUERY

  if [ -n "$selected" ]; then
    local note_id=$(echo "$selected" | sed -E 's/^\[([0-9]+)\].*/\1/')
    nb edit "$note_id"
  fi
}

# --- reminder: macOS リマインダーに追加 ---
# 使い方: reminder "タイトル" ["メモ"] "YYYY/MM/DD" ["HH:MM"] ["リスト名"]
reminder() {
  local title="$1"
  local memo="${2:-}"
  local date="$3"
  local time="${4:-}"
  local list="${5:-一般}"

  if [[ -z "$title" || -z "$date" ]]; then
    echo "使い方: reminder \"タイトル\" [\"メモ\"] \"YYYY/MM/DD\" [\"HH:MM\"] [\"カテゴリ\"]"
    return 1
  fi

  local due_date
  if [[ -n "$time" ]]; then
    due_date="${date} ${time}"
  else
    due_date="${date} 09:00"
  fi

  osascript -e "
tell application \"Reminders\"
  tell list \"${list}\"
    make new reminder with properties {name:\"${title}\", body:\"${memo}\", due date:date \"${due_date}\"}
  end tell
end tell"
  echo "追加しました: ${title} (${due_date}) [${list}]"
}

# --- qiita-post: Qiita 投稿 ---
qiita-post() {
  local token=$(grep QIITA_TOKEN ~/Documents/05_vim/qiita-sync/.env | cut -d= -f2)
  QIITA_TOKEN="$token" bun run ~/Documents/05_vim/qiita-sync/post.ts "$1"
}


# =================================================
# Extra Configurations & Hidden Secrets
# =================================================

# --- 他の zsh 設定を読み込む ---
if [ -f "$HOME/.config/zsh/.zshrc" ]; then
  source "$HOME/.config/zsh/.zshrc"
fi

# --- hidden ディレクトリ内の機密設定 (Rails Master Key など) ---
if [ -d "$HOME/.config/zsh/hidden" ]; then
  for file in "$HOME/.config/zsh/hidden"/*.zsh; do
    source "$file"
  done
fi

. "$HOME/.local/bin/env"

# Hermes Agent — ensure ~/.local/bin is on PATH
export PATH="$HOME/.local/bin:$PATH"

# Obsidian _daily_log の raw を手動整理（launchd と同じスクリプト）
alias obs-worker="$HOME/.claude/scripts/daily-obsidian-organize.sh"
