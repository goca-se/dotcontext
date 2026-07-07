# ── Command: update ───────────────────────────────────────────────────────────

cmd_update() {
  local templates_only=false
  local cli_only=false
  local auto_yes=false
  local dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --templates) templates_only=true; shift ;;
      --cli) cli_only=true; shift ;;
      --yes|-y) auto_yes=true; shift ;;
      --dry-run) dry_run=true; shift ;;
      *) shift ;;
    esac
  done

  if [ "$templates_only" = true ]; then
    cmd_update_templates "$auto_yes" "$dry_run"
  elif [ "$cli_only" = true ]; then
    cmd_update_cli
  else
    # Default: update CLI, then templates if in a project
    cmd_update_cli
    if [ -d ".context" ]; then
      echo ""
      # Re-exec with new binary so template list is up to date
      local new_bin
      new_bin=$(command -v dotcontext 2>/dev/null || echo "")
      if [ -n "$new_bin" ] && [ -x "$new_bin" ]; then
        local new_ver
        new_ver=$("$new_bin" --version 2>/dev/null | sed 's/dotcontext //')
        if [ "$new_ver" != "$VERSION" ]; then
          local args="update --templates"
          [ "$auto_yes" = "true" ] && args="$args --yes"
          [ "$dry_run" = "true" ] && args="$args --dry-run"
          exec "$new_bin" $args
        fi
      fi
      cmd_update_templates "$auto_yes" "$dry_run"
    fi
  fi
}

cmd_update_cli() {
  start_spinner "Checking for CLI updates..."

  # Get latest version tag from GitHub (try releases first, then tags)
  local latest_version
  local latest_tag
  local api_response

  if command -v curl &> /dev/null; then
    api_response=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null)
    latest_tag=$(echo "$api_response" | grep '"tag_name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
    latest_version=$(echo "$latest_tag" | sed 's/^v//')

    if [ -z "$latest_version" ]; then
      api_response=$(curl -fsSL "https://api.github.com/repos/${REPO}/tags" 2>/dev/null)
      latest_tag=$(echo "$api_response" | grep '"name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
      latest_version=$(echo "$latest_tag" | sed 's/^v//')
    fi
  else
    api_response=$(wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null)
    latest_tag=$(echo "$api_response" | grep '"tag_name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
    latest_version=$(echo "$latest_tag" | sed 's/^v//')

    if [ -z "$latest_version" ]; then
      api_response=$(wget -qO- "https://api.github.com/repos/${REPO}/tags" 2>/dev/null)
      latest_tag=$(echo "$api_response" | grep '"name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
      latest_version=$(echo "$latest_tag" | sed 's/^v//')
    fi
  fi

  if [ -z "$latest_version" ]; then
    stop_spinner
    print_red "Could not check latest version."
    return 1
  fi

  if [ "$VERSION" = "$latest_version" ]; then
    stop_spinner "$(printf "${GREEN}${ICON_SUCCESS} CLI already at latest version ($VERSION)${NC}")"
    return 0
  fi

  stop_spinner "$(printf "${GRAY}Current: $VERSION → Latest: $latest_version${NC}")"

  # Find installation path
  local install_path=$(command -v dotcontext)
  if [ -z "$install_path" ]; then
    install_path="/usr/local/bin/dotcontext"
  fi

  # Download from release tag (not main branch) to avoid unreleased code
  local release_url="https://raw.githubusercontent.com/${REPO}/${latest_tag}/dotcontext"
  start_spinner "Downloading from release ${latest_tag}..."

  local tmp_file=$(mktemp)
  download "$release_url" "$tmp_file"
  stop_spinner

  # Verify download
  if [ ! -s "$tmp_file" ] || ! head -1 "$tmp_file" | grep -q "^#!/bin/bash"; then
    print_red "Error: Download failed"
    rm -f "$tmp_file"
    return 1
  fi

  chmod +x "$tmp_file"

  # Install
  if [ -w "$(dirname "$install_path")" ]; then
    mv "$tmp_file" "$install_path"
  else
    print_yellow "Need sudo to update $install_path"
    sudo mv "$tmp_file" "$install_path"
    sudo chmod +x "$install_path"
  fi

  print_green "${ICON_SUCCESS} CLI updated to $latest_version"
}

cmd_update_templates() {
  local auto_yes="$1"
  local dry_run="$2"

  if [ ! -d ".context" ]; then
    print_red "No .context directory. Run \`dotcontext init\` first."
    return 1
  fi

  # Migration: move skills from .context/skills/ to .claude/skills/
  if [ -d ".context/skills" ] && [ ! -d ".claude/skills" ]; then
    mkdir -p ".claude/skills"
    cp -r .context/skills/* .claude/skills/ 2>/dev/null || true
    rm -rf .context/skills
    print_green "  Migrated .context/skills/ → .claude/skills/"
  elif [ -d ".context/skills" ] && [ -d ".claude/skills" ]; then
    # Both exist — merge old into new (don't overwrite existing)
    for dir in .context/skills/*/; do
      local skill_name=$(basename "$dir")
      if [ ! -d ".claude/skills/$skill_name" ]; then
        cp -r "$dir" ".claude/skills/$skill_name"
      fi
    done
    rm -rf .context/skills
    print_green "  Migrated remaining skills from .context/skills/ → .claude/skills/"
  fi

  # Migration: adopt AGENTS.md as the canonical instruction source (ADR-016).
  # Legacy projects have a content-bearing CLAUDE.md and no AGENTS.md. Moving
  # the content to AGENTS.md (and leaving CLAUDE.md as an @import stub) is
  # content- and behavior-preserving for Claude, and lets the other agents read
  # the same instructions natively.
  local _stub_comment='<!-- Project instructions live in AGENTS.md (shared canonical source). Edit that file. -->'
  if [ -f "CLAUDE.md" ] && [ ! -f "AGENTS.md" ] && ! grep -q '@AGENTS.md' "CLAUDE.md" 2>/dev/null; then
    if [ "$dry_run" = "true" ]; then
      print_gray "  [dry-run] would migrate CLAUDE.md → AGENTS.md (+ CLAUDE.md import stub)"
    else
      local do_migrate=false
      if [ "$auto_yes" = "true" ]; then
        do_migrate=true
      elif confirm_yes "  Adopt AGENTS.md as the shared instructions file? (Claude keeps working via import)"; then
        do_migrate=true
      fi
      if [ "$do_migrate" = true ]; then
        mv "CLAUDE.md" "AGENTS.md"
        printf '%s\n\n%s\n' "$_stub_comment" '@AGENTS.md' > "CLAUDE.md"
        print_green "  Migrated CLAUDE.md → AGENTS.md (Claude reads it via @import)"
      fi
    fi
  fi

  # Add a Gemini import stub when the Gemini CLI is present and AGENTS.md exists.
  if agent_detect gemini && [ -f "AGENTS.md" ] && [ ! -f "GEMINI.md" ]; then
    if [ "$dry_run" = "true" ]; then
      print_gray "  [dry-run] would add GEMINI.md (imports AGENTS.md)"
    else
      printf '%s\n\n%s\n' "$_stub_comment" '@AGENTS.md' > "GEMINI.md"
      print_green "  Added GEMINI.md (imports AGENTS.md)"
    fi
  fi

  # Mirror skills to .agents/skills/ when a non-Claude agent is present (ADR-017).
  if [ -d ".claude/skills" ] && [ ! -e ".agents/skills" ]; then
    local _na=false _aid
    for _aid in $(detect_agents); do [ "$_aid" != "claude" ] && _na=true; done
    if [ "$_na" = true ]; then
      if [ "$dry_run" = "true" ]; then
        print_gray "  [dry-run] would mirror .claude/skills → .agents/skills (non-Claude agent detected)"
      else
        link_or_copy_dir ".claude/skills" ".agents/skills"
        print_green "  Mirrored skills to .agents/skills/"
      fi
    fi
  fi

  start_spinner "Checking templates..."

  # MANAGED templates: dotcontext-owned code (commands, templates that drive commands).
  # Always offered for update — diff is shown, user can accept or skip.
  declare -a managed_templates=(
    "templates/.claude/commands/setup-context.md:.claude/commands/setup-context.md"
    "templates/.claude/commands/code-review.md:.claude/commands/code-review.md"
    "templates/.claude/commands/spec-dc.md:.claude/commands/spec-dc.md"
    "templates/.claude/commands/plan-dc.md:.claude/commands/plan-dc.md"
    "templates/.claude/commands/execute-dc.md:.claude/commands/execute-dc.md"
    "templates/.claude/commands/add-decision.md:.claude/commands/add-decision.md"
    "templates/.claude/commands/add-skill.md:.claude/commands/add-skill.md"
    "templates/.claude/commands/add-command.md:.claude/commands/add-command.md"
    "templates/.claude/commands/create-pr.md:.claude/commands/create-pr.md"
    "templates/.claude/commands/pr-comment.md:.claude/commands/pr-comment.md"
    "templates/.claude/commands/deep-context.md:.claude/commands/deep-context.md"
    "templates/.claude/commands/fix-bug.md:.claude/commands/fix-bug.md"
    "templates/.claude/commands/commit.md:.claude/commands/commit.md"
    "templates/.claude/scripts/statusline.sh:.claude/scripts/statusline.sh"
    "templates/.claude/agents/code-review/compliance-checker.md:.claude/agents/code-review/compliance-checker.md"
    "templates/.claude/agents/code-review/bug-detector.md:.claude/agents/code-review/bug-detector.md"
    "templates/.claude/agents/code-review/security-analyst.md:.claude/agents/code-review/security-analyst.md"
    "templates/.claude/agents/deep-context/step1-overview.md:.claude/agents/deep-context/step1-overview.md"
    "templates/.claude/agents/deep-context/step2-subsystems.md:.claude/agents/deep-context/step2-subsystems.md"
    "templates/.claude/agents/deep-context/step3-drill.md:.claude/agents/deep-context/step3-drill.md"
    "templates/.claude/agents/deep-context/step4-dataflow.md:.claude/agents/deep-context/step4-dataflow.md"
    "templates/.claude/agents/fix-bug/investigator.md:.claude/agents/fix-bug/investigator.md"
    "templates/.claude/agents/fix-bug/fix-conservative.md:.claude/agents/fix-bug/fix-conservative.md"
    "templates/.claude/agents/fix-bug/fix-minimal.md:.claude/agents/fix-bug/fix-minimal.md"
    "templates/.claude/agents/fix-bug/fix-refactor.md:.claude/agents/fix-bug/fix-refactor.md"
    "templates/.claude/agents/fix-bug/reviewer.md:.claude/agents/fix-bug/reviewer.md"
    "templates/.claude/agents/spec-dc/reviewer-pro.md:.claude/agents/spec-dc/reviewer-pro.md"
    "templates/.claude/agents/spec-dc/reviewer-fast.md:.claude/agents/spec-dc/reviewer-fast.md"
    "templates/.claude/agents/plan-dc/reviewer-pro.md:.claude/agents/plan-dc/reviewer-pro.md"
    "templates/.claude/agents/plan-dc/reviewer-fast.md:.claude/agents/plan-dc/reviewer-fast.md"
    "templates/.claude/agents/execute-dc/reviewer-pro.md:.claude/agents/execute-dc/reviewer-pro.md"
    "templates/.claude/agents/execute-dc/reviewer-fast.md:.claude/agents/execute-dc/reviewer-fast.md"
  )

  # SEED templates: created once during init, customized by user or /setup-context.
  # Only added if missing — never offered for overwrite to protect user content.
  declare -a seed_templates=(
    "templates/AGENTS.md:AGENTS.md"
    "templates/.context/decisions/README.md:.context/decisions/README.md"
    "templates/.context/specs/README.md:.context/specs/README.md"
    "templates/.context/plans/README.md:.context/plans/README.md"
    "templates/.claude/skills/bug-reproduction/SKILL.md:.claude/skills/bug-reproduction/SKILL.md"
    "templates/.claude/skills/batch-operations/SKILL.md:.claude/skills/batch-operations/SKILL.md"
    "templates/.claude/skills/git-platform/SKILL.md:.claude/skills/git-platform/SKILL.md"
    "templates/.claude/skills/update-api-documentation/SKILL.md:.claude/skills/update-api-documentation/SKILL.md"
  )

  # Create temp directory for downloads
  local tmp_dir=$(mktemp -d)
  trap "rm -rf $tmp_dir" EXIT

  # Arrays to categorize files
  declare -a new_files=()
  declare -a modified_files=()
  declare -a unchanged_files=()
  declare -a seed_new_files=()
  declare -a seed_skipped_files=()

  # Process managed templates (can be updated)
  for mapping in "${managed_templates[@]}"; do
    local remote_path="${mapping%%:*}"
    local local_path="${mapping##*:}"
    local tmp_file="$tmp_dir/$(echo "$local_path" | sed 's|/|__|g')"

    if ! download "${BASE_URL}/${remote_path}" "$tmp_file" 2>/dev/null; then
      print_red "  failed to download: $remote_path"
      continue
    fi

    if [ ! -f "$local_path" ]; then
      new_files+=("$mapping")
    elif ! diff -q "$local_path" "$tmp_file" >/dev/null 2>&1; then
      modified_files+=("$mapping")
    else
      unchanged_files+=("$mapping")
    fi
  done

  # Process seed templates (create-only, never overwrite)
  for mapping in "${seed_templates[@]}"; do
    local remote_path="${mapping%%:*}"
    local local_path="${mapping##*:}"
    local tmp_file="$tmp_dir/$(echo "$local_path" | sed 's|/|__|g')"

    if ! download "${BASE_URL}/${remote_path}" "$tmp_file" 2>/dev/null; then
      print_red "  failed to download: $remote_path"
      continue
    fi

    if [ ! -f "$local_path" ]; then
      # Seed file missing — will be added
      seed_new_files+=("$mapping")
    else
      # Seed file exists — never touch it, even if different
      seed_skipped_files+=("$mapping")
    fi
  done

  stop_spinner

  # Display summary
  echo ""
  local has_changes=false

  if [ ${#new_files[@]} -gt 0 ] || [ ${#seed_new_files[@]} -gt 0 ]; then
    has_changes=true
    for mapping in "${new_files[@]}"; do
      local local_path="${mapping##*:}"
      printf "  ${GREEN}${ICON_ADD}${NC} %s ${GRAY}(new)${NC}\n" "$local_path"
    done
    for mapping in "${seed_new_files[@]}"; do
      local local_path="${mapping##*:}"
      printf "  ${GREEN}${ICON_ADD}${NC} %s ${GRAY}(new — seed template)${NC}\n" "$local_path"
    done
  fi

  if [ ${#modified_files[@]} -gt 0 ]; then
    has_changes=true
    for mapping in "${modified_files[@]}"; do
      local local_path="${mapping##*:}"
      printf "  ${YELLOW}${ICON_MODIFY}${NC} %s ${GRAY}(modified)${NC}\n" "$local_path"
    done
  fi

  if [ ${#unchanged_files[@]} -gt 0 ]; then
    for mapping in "${unchanged_files[@]}"; do
      local local_path="${mapping##*:}"
      printf "  ${GRAY}${ICON_UNCHANGED}${NC} %s ${GRAY}(unchanged)${NC}\n" "$local_path"
    done
  fi

  if [ ${#seed_skipped_files[@]} -gt 0 ]; then
    for mapping in "${seed_skipped_files[@]}"; do
      local local_path="${mapping##*:}"
      printf "  ${CYAN}${ICON_MANAGED}${NC} %s ${GRAY}(user-managed — skipped)${NC}\n" "$local_path"
    done
  fi

  local total_new=$((${#new_files[@]} + ${#seed_new_files[@]}))
  echo ""
  printf "Summary: ${GREEN}%d to add${NC}, ${YELLOW}%d to update${NC}, ${GRAY}%d unchanged${NC}, ${CYAN}%d user-managed${NC}\n" \
    "$total_new" "${#modified_files[@]}" "${#unchanged_files[@]}" "${#seed_skipped_files[@]}"

  # If no changes, exit early
  if [ "$has_changes" = false ]; then
    echo ""
    print_green "${ICON_SUCCESS} All templates up to date"
    return 0
  fi

  # Dry run - just show what would happen
  if [ "$dry_run" = "true" ]; then
    echo ""
    print_gray "Dry run - no changes made"
    return 0
  fi

  # Ask user what to do
  local action="n"
  if [ "$auto_yes" = "true" ]; then
    action="y"
  elif [ ${#modified_files[@]} -gt 0 ]; then
    echo ""
    printf "Update %d existing file(s)? [y/N/d] " "${#modified_files[@]}"
    printf "${GRAY}(y=yes, N=no, d=show diffs)${NC} "
    read -r action
    action="${action:-n}"

    # Handle diff option
    if [[ "$action" =~ ^[Dd] ]]; then
      echo ""
      for mapping in "${modified_files[@]}"; do
        local remote_path="${mapping%%:*}"
        local local_path="${mapping##*:}"
        local tmp_file="$tmp_dir/$(echo "$local_path" | sed 's|/|__|g')"

        print_cyan "=== $local_path ==="
        # diff exits 1 when files differ (normal), 2 when error (e.g. --color not supported)
        diff --color=auto -u "$local_path" "$tmp_file" 2>/dev/null
        if [ $? -eq 2 ]; then
          diff -u "$local_path" "$tmp_file"
        fi
        echo ""
      done

      printf "Update %d existing file(s)? [y/N] " "${#modified_files[@]}"
      read -r action
      action="${action:-n}"
    fi
  else
    action="y"  # Only new files, no need to ask
  fi

  # Apply changes
  local added=0
  local updated=0

  # Always add new managed files
  for mapping in "${new_files[@]}"; do
    local local_path="${mapping##*:}"
    local dir_path=$(dirname "$local_path")
    local tmp_file="$tmp_dir/$(echo "$local_path" | sed 's|/|__|g')"

    mkdir -p "$dir_path"
    cp "$tmp_file" "$local_path"
    ((added++))
  done

  # Always add new seed files (they don't exist yet)
  for mapping in "${seed_new_files[@]}"; do
    local local_path="${mapping##*:}"
    local dir_path=$(dirname "$local_path")
    local tmp_file="$tmp_dir/$(echo "$local_path" | sed 's|/|__|g')"

    mkdir -p "$dir_path"
    cp "$tmp_file" "$local_path"
    ((added++))
  done

  # Update modified managed files only if user said yes
  if [[ "$action" =~ ^[Yy] ]]; then
    for mapping in "${modified_files[@]}"; do
      local local_path="${mapping##*:}"
      local tmp_file="$tmp_dir/$(echo "$local_path" | sed 's|/|__|g')"

      cp "$tmp_file" "$local_path"
      ((updated++))
    done
  fi

  # Declarative cleanup: remove stale files from managed-only directories
  # NOTE: .claude/commands/ is excluded — users create custom commands there via /add-command
  cleanup_managed_dir ".claude/agents/code-review" \
    compliance-checker.md bug-detector.md security-analyst.md
  cleanup_managed_dir ".claude/agents/deep-context" \
    step1-overview.md step2-subsystems.md step3-drill.md step4-dataflow.md
  cleanup_managed_dir ".claude/agents/fix-bug" \
    investigator.md fix-conservative.md fix-minimal.md fix-refactor.md reviewer.md
  cleanup_managed_dir ".claude/agents/spec-dc" \
    reviewer-pro.md reviewer-fast.md
  cleanup_managed_dir ".claude/agents/plan-dc" \
    reviewer-pro.md reviewer-fast.md
  cleanup_managed_dir ".claude/agents/execute-dc" \
    reviewer-pro.md reviewer-fast.md
  cleanup_managed_dir ".claude/scripts" \
    statusline.sh

  # ── Deliver renamed workflows to existing per-harness installs (ADR-020) ──
  # Claude picks up spec/plan/execute-dc via managed_templates above. opencode and
  # Copilot keep their commands in .opencode/command / .github/prompts, emitted only
  # by emit_agent_commands (create-only). Re-run it here — inferring the harnesses in
  # use from the dirs that exist — so those installs also get the new commands.
  if [ "$dry_run" != "true" ]; then
    local _reemit=""
    [ -d ".opencode/command" ] && _reemit="$_reemit opencode"
    [ -d ".github/prompts" ]   && _reemit="$_reemit copilot"
    _reemit="${_reemit# }"
    [ -n "$_reemit" ] && emit_agent_commands "$_reemit" 2>/dev/null || true
  fi

  # ── Migration notice: the PRP flow is now spec → plan → execute (ADR-020) ──
  # Non-destructive — the old command files are kept and still work; tell the user so
  # they can clean up, and remind AGENTS.md-only harnesses (their table isn't rewritten).
  if [ -f ".claude/commands/generate-prp.md" ] || [ -f ".opencode/command/generate-prp.md" ] || \
     [ -f ".github/prompts/generate-prp.prompt.md" ] || grep -q "generate-prp" "AGENTS.md" 2>/dev/null; then
    echo ""
    print_yellow "Heads up: the PRP flow is now spec -> plan -> execute (ADR-020)."
    print_gray "  /generate-prp  ->  /spec-dc + /plan-dc      /execute-prp  ->  /execute-dc"
    print_gray "  Your old generate-prp/execute-prp were kept and still work -- remove them when ready."
    print_gray "  Gemini/Cursor/Codex: refresh the '## Workflows' table in AGENTS.md (it is not auto-updated)."
  fi

  echo ""
  if [ $added -gt 0 ] || [ $updated -gt 0 ]; then
    if [ $added -gt 0 ]; then
      print_green "${ICON_SUCCESS} Added $added new file(s)"
    fi
    if [ $updated -gt 0 ]; then
      print_green "${ICON_SUCCESS} Updated $updated file(s)"
    fi
  else
    print_gray "No changes made"
  fi

  # Offer MCP configuration if .mcp.json doesn't exist
  if [ ! -f ".mcp.json" ]; then
    local add_context7=false
    local add_atlassian=false

    if [ "$auto_yes" = "true" ]; then
      add_context7=true
      add_atlassian=true
    else
      echo ""
      print_blue "MCP Servers"
      print_gray "Configure Model Context Protocol servers for your agents"
      echo ""

      if confirm_yes "  Add Context7? (up-to-date library docs for LLMs)"; then
        add_context7=true
      fi

      if confirm_yes "  Add Atlassian? (Jira + Confluence via OAuth)"; then
        add_atlassian=true
      fi
    fi

    setup_mcp "$add_context7" "$add_atlassian"
  fi
}
