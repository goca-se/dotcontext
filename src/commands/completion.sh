# ── Command: completion ───────────────────────────────────────────────────────

cmd_completion() {
  local shell="${1:-}"
  if [ -z "$shell" ]; then
    if [ -n "$ZSH_VERSION" ]; then
      shell="zsh"
    else
      shell="bash"
    fi
  fi

  case "$shell" in
    bash)
      cat << 'BASH_COMP'
_dotcontext() {
  local cur prev commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  commands="init update doctor completion"

  case "$prev" in
    dotcontext)
      COMPREPLY=( $(compgen -W "$commands --help --version" -- "$cur") )
      return 0
      ;;
    init)
      COMPREPLY=( $(compgen -W "--name -n --yes -y --no-setup" -- "$cur") )
      return 0
      ;;
    update)
      COMPREPLY=( $(compgen -W "--cli --templates --yes -y --dry-run" -- "$cur") )
      return 0
      ;;
    completion)
      COMPREPLY=( $(compgen -W "bash zsh" -- "$cur") )
      return 0
      ;;
  esac

  COMPREPLY=( $(compgen -W "$commands --help --version" -- "$cur") )
}
complete -F _dotcontext dotcontext
BASH_COMP
      ;;
    zsh)
      cat << 'ZSH_COMP'
#compdef dotcontext

_dotcontext() {
  local -a commands
  commands=(
    'init:Initialize .context structure + open Claude Code'
    'update:Update CLI and/or templates'
    'doctor:Check project setup health'
    'completion:Generate shell tab completions'
  )

  _arguments -C \
    '1:command:->command' \
    '*::arg:->args'

  case "$state" in
    command)
      _describe 'command' commands
      _arguments \
        '--help[Show help]' \
        '-h[Show help]' \
        '--version[Show version]' \
        '-v[Show version]'
      ;;
    args)
      case "${words[1]}" in
        init)
          _arguments \
            '--name[Project name]:name:' \
            '-n[Project name]:name:' \
            '--yes[Skip prompts]' \
            '-y[Skip prompts]' \
            '--no-setup[Skip automatic /setup-context]'
          ;;
        update)
          _arguments \
            '--cli[Only update CLI]' \
            '--templates[Only update templates]' \
            '--yes[Update without asking]' \
            '-y[Update without asking]' \
            '--dry-run[Show what would change]'
          ;;
        completion)
          _arguments '1:shell:(bash zsh)'
          ;;
      esac
      ;;
  esac
}

compdef _dotcontext dotcontext
ZSH_COMP
      ;;
    *)
      print_red "Unknown shell: $shell (supported: bash, zsh)"
      return 1
      ;;
  esac
}
