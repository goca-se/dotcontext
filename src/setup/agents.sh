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

# Echo "url:target" instruction-file seed mappings for the selected agent ids.
# AGENTS.md (canonical) is always first; import-mode agents add their stub.
# Native agents need no extra file (they read AGENTS.md directly).
agent_instruction_seeds() {
  local selected="$1" id target seen=" "
  echo "${BASE_URL}/templates/AGENTS.md:AGENTS.md"
  for id in $selected; do
    [ "$(agent_emit_mode "$id")" = "import" ] || continue
    target="$(agent_instructions_file "$id")"
    case "$seen" in *" $target "*) continue ;; esac
    seen="$seen$target "
    echo "${BASE_URL}/templates/${target}:${target}"
  done
}
