#!/bin/bash

_km_complete() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  opts="add use switch backup-restore backup-list backup-prune delete rename-context list help"

  if [[ ${COMP_CWORD} -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
  fi
}
complete -F _km_complete km
complete -F _km_complete kube-merge
