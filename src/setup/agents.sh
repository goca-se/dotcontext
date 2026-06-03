# ── Agent Adapter Registry ──────────────────────────────────────────────────
# Each supported coding agent is one entry. Adding an agent means adding it to
# AGENT_IDS and the case arms below — nothing else in the toolkit hard-codes an
# agent. (ADR-016)
#
# Emit modes for the project-instructions file:
#   import — a thin stub that @-imports AGENTS.md (Claude Code, Gemini CLI)
#   native — reads AGENTS.md directly; needs no file of its own (Codex,
#            opencode, Copilot, Cursor incl. the cursor-agent CLI)
#
# AGENTS.md itself is the canonical single source and is always emitted.

AGENT_IDS="claude codex opencode gemini copilot cursor"

agent_name() {
  case "$1" in
    claude)   echo "Claude Code" ;;
    codex)    echo "OpenAI Codex" ;;
    opencode) echo "opencode" ;;
    gemini)   echo "Gemini CLI" ;;
    copilot)  echo "GitHub Copilot" ;;
    cursor)   echo "Cursor (cursor-agent)" ;;
    *)        echo "$1" ;;
  esac
}

# Detection: is the agent's CLI installed?
agent_detect() {
  case "$1" in
    claude)   command -v claude >/dev/null 2>&1 ;;
    codex)    command -v codex >/dev/null 2>&1 ;;
    opencode) command -v opencode >/dev/null 2>&1 ;;
    gemini)   command -v gemini >/dev/null 2>&1 ;;
    copilot)  command -v copilot >/dev/null 2>&1 || \
              { command -v gh >/dev/null 2>&1 && gh extension list 2>/dev/null | grep -qi copilot; } ;;
    cursor)   command -v cursor-agent >/dev/null 2>&1 ;;
    *)        return 1 ;;
  esac
}

# The instruction file this agent reads.
agent_instructions_file() {
  case "$1" in
    claude)   echo "CLAUDE.md" ;;
    gemini)   echo "GEMINI.md" ;;
    *)        echo "AGENTS.md" ;;
  esac
}

# How this agent gets its instructions: import | native
agent_emit_mode() {
  case "$1" in
    claude|gemini) echo "import" ;;
    *)             echo "native" ;;
  esac
}

# Echo the ids of detected (installed) agents, space-separated.
detect_agents() {
  local id out=""
  for id in $AGENT_IDS; do
    if agent_detect "$id"; then out="$out $id"; fi
  done
  echo "${out# }"
}

# Echo "url|target" instruction-file seed mappings for the selected agent ids.
# AGENTS.md (canonical) is always first; import-mode agents add their stub.
# Native agents need no extra file (they read AGENTS.md directly).
# The "|" separator can't appear in a URL or a filename, so consumers parse it
# unambiguously: url="${mapping%|*}", target="${mapping##*|}".
agent_instruction_seeds() {
  local selected="$1" id target seen=" "
  echo "${BASE_URL}/templates/AGENTS.md|AGENTS.md"
  for id in $selected; do
    [ "$(agent_emit_mode "$id")" = "import" ] || continue
    target="$(agent_instructions_file "$id")"
    case "$seen" in *" $target "*) continue ;; esac
    seen="$seen$target "
    echo "${BASE_URL}/templates/${target}|${target}"
  done
}

# True if the id list contains a given agent.
agents_include() {
  case " $1 " in *" $2 "*) return 0 ;; *) return 1 ;; esac
}

# Resolve which harnesses to instantiate. Sets the global SELECTED_AGENTS.
# Priority: explicit --agents list > non-interactive (detected, fallback claude)
# > interactive (confirm each detected agent; offer Claude if none).
# Must NOT run inside $(...) — it prompts on stdout. (ADR-016)
SELECTED_AGENTS=""
resolve_selected_agents() {
  local agents_flag="$1" skip_prompts="$2"
  SELECTED_AGENTS=""

  if [ -n "$agents_flag" ]; then
    local IFS=',' id
    for id in $agents_flag; do
      id="$(echo "$id" | tr -d '[:space:]')"
      [ -z "$id" ] && continue
      if agents_include "$AGENT_IDS" "$id"; then
        SELECTED_AGENTS="$SELECTED_AGENTS $id"
      else
        print_yellow "  unknown agent '$id' (skipped) — known: $AGENT_IDS"
      fi
    done
    SELECTED_AGENTS="${SELECTED_AGENTS# }"
    return 0
  fi

  local detected; detected="$(detect_agents)"

  if [ "$skip_prompts" = "true" ]; then
    SELECTED_AGENTS="$detected"
    [ -z "$SELECTED_AGENTS" ] && SELECTED_AGENTS="claude"
    return 0
  fi

  local id
  if [ -n "$detected" ]; then
    print_blue "Detected agents — choose which to set up:"
    for id in $detected; do
      if confirm_yes "  Set up for $(agent_name "$id")?"; then
        SELECTED_AGENTS="$SELECTED_AGENTS $id"
      fi
    done
  fi
  SELECTED_AGENTS="${SELECTED_AGENTS# }"

  if [ -z "$SELECTED_AGENTS" ]; then
    if confirm_yes "  No agent selected — set up for Claude Code?"; then
      SELECTED_AGENTS="claude"
    fi
  fi
}

# Create $2 as a symlink to $1 (relative), or copy if symlinks aren't available.
# No-op if $2 already exists. Used to mirror the skills dir across ecosystems.
link_or_copy_dir() {
  local src="$1" dst="$2"
  [ -d "$src" ] || return 0
  if [ -e "$dst" ] || [ -L "$dst" ]; then return 0; fi
  mkdir -p "$(dirname "$dst")"
  ln -s "../$src" "$dst" 2>/dev/null || cp -r "$src" "$dst"
}

# ── Per-agent hooks ───────────────────────────────────────────────────────────
# Wire a "task finished / needs attention" notification per selected agent.
# Claude keeps its richer hooks (notify + tool-failure-guard) via
# setup_notifications. Non-Claude agents get a notification hook in their native
# config format, pointing at a shared, arg-driven notify.sh (it ignores stdin,
# so the same script works regardless of each agent's hook JSON contract).
# Best-effort + create-only: never clobbers an existing agent config.
NOTIFY_SHARED=".context/scripts/notify.sh"

ensure_shared_notify() {
  [ -f "$NOTIFY_SHARED" ] && return 0
  mkdir -p ".context/scripts"
  download "${BASE_URL}/scripts/notify.sh" "$NOTIFY_SHARED" && chmod +x "$NOTIFY_SHARED"
}

setup_agent_hooks() {
  local selected="$1" id done_any=false
  for id in $selected; do
    case "$id" in
      claude)
        setup_notifications 2>/dev/null || true
        done_any=true
        ;;
      codex)
        ensure_shared_notify
        if [ ! -f ".codex/hooks.json" ]; then
          mkdir -p ".codex"
          cat > ".codex/hooks.json" <<JSON
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "$NOTIFY_SHARED 'Codex' 'Task completed' success" } ] }
    ]
  }
}
JSON
          print_gray "  hooks: .codex/hooks.json"
          done_any=true
        fi
        ;;
      gemini)
        ensure_shared_notify
        if [ ! -f ".gemini/settings.json" ]; then
          mkdir -p ".gemini"
          cat > ".gemini/settings.json" <<JSON
{
  "hooks": {
    "Notification": [
      { "hooks": [ { "type": "command", "command": "$NOTIFY_SHARED 'Gemini' 'Needs your attention' question" } ] }
    ],
    "AfterAgent": [
      { "hooks": [ { "type": "command", "command": "$NOTIFY_SHARED 'Gemini' 'Task completed' success" } ] }
    ]
  }
}
JSON
          print_gray "  hooks: .gemini/settings.json"
          done_any=true
        fi
        ;;
      copilot)
        ensure_shared_notify
        if [ ! -f ".github/hooks/dotcontext-notify.json" ]; then
          mkdir -p ".github/hooks"
          cat > ".github/hooks/dotcontext-notify.json" <<JSON
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "$NOTIFY_SHARED 'Copilot' 'Task completed' success" } ] }
    ]
  }
}
JSON
          print_gray "  hooks: .github/hooks/dotcontext-notify.json"
          done_any=true
        fi
        ;;
      cursor)
        ensure_shared_notify
        if [ ! -f ".cursor/hooks.json" ]; then
          mkdir -p ".cursor"
          cat > ".cursor/hooks.json" <<JSON
{
  "version": 1,
  "hooks": {
    "stop": [
      { "command": "$NOTIFY_SHARED 'Cursor' 'Task completed' success" }
    ]
  }
}
JSON
          print_gray "  hooks: .cursor/hooks.json"
          done_any=true
        fi
        ;;
      opencode)
        ensure_shared_notify
        if [ ! -f ".opencode/plugins/dotcontext-notify.js" ]; then
          mkdir -p ".opencode/plugins"
          cat > ".opencode/plugins/dotcontext-notify.js" <<'JS'
// dotcontext: fire an OS notification when the session goes idle.
export const DotcontextNotify = async ({ $ }) => ({
  event: async ({ event }) => {
    if (event?.type === "session.idle") {
      await $`.context/scripts/notify.sh 'opencode' 'Task completed' success`.catch(() => {})
    }
  },
})
JS
          print_gray "  hooks: .opencode/plugins/dotcontext-notify.js"
          done_any=true
        fi
        ;;
    esac
  done
  [ "$done_any" = true ] || true
}
