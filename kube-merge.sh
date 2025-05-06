#!/bin/bash
####################
#
# Author: Bruno Bernard (eznix86)
# Enhanced with bash-rollback
#
####################

# Source the bash-rollback utility for safe operations
source <(curl -s https://raw.githubusercontent.com/eznix86/bash-rollback/main/rollback.sh)

set -e

KUBECONFIG_DIR=~/.kube-merge
BACKUP_ROOT="$KUBECONFIG_DIR/backups"
MAIN_CONFIG=~/.kube/config
TEMP_CONFIG=~/.kube/config.temp

mkdir -p "$BACKUP_ROOT"

function usage() {
  echo "Usage:"
  echo "  km add <path-to-kubeconfig> [new-context-name] [-i|--interactive]"
  echo "  km switch <context-name>"
  echo "  km backup-restore <datetime>"
  echo "  km backup-list"
  echo "  km backup-prune"
  echo "  km delete <context-name> [--force]"
  echo "  km rename-context <old> <new>"
  echo "  km list"
  echo "  km [-h|--help]"
}

function backup_config() {
  local datetime=$(date "+%Y%m%d%H%M%S")
  local backup_dir="$BACKUP_ROOT/config.$datetime.bak"
  mkdir -p "$backup_dir"
  cp "$MAIN_CONFIG" "$backup_dir/config.bak"
  echo "Backup created: $backup_dir"
}

function merge_configs() {
  local config_paths="$1"
  local timestamp=$(date +%s)
  local temp_backup="$BACKUP_ROOT/pre_merge.$timestamp"
  
  # Create backup of current config
  mkdir -p "$temp_backup"
  cp "$MAIN_CONFIG" "$temp_backup/config" 2>/dev/null || true
  rb "cp '$temp_backup/config' '$MAIN_CONFIG' 2>/dev/null || true; rm -rf '$temp_backup'"
  
  # Set KUBECONFIG to include all paths
  export KUBECONFIG="$MAIN_CONFIG"
  if [ -n "$config_paths" ]; then
    export KUBECONFIG="$KUBECONFIG:$config_paths"
  fi
  
  # Display the configs we're about to merge
  echo "Merging kubeconfigs: $KUBECONFIG"
  
  # Flatten the merged config and save it
  kubectl config view --flatten > "$TEMP_CONFIG"
  backup_config
  mv "$TEMP_CONFIG" "$MAIN_CONFIG"
  chmod 600 "$MAIN_CONFIG"
  echo "Config merged into $MAIN_CONFIG"
  
  # Cleanup
  rm -rf "$temp_backup"
}

function add_config() {
  local src="$1"
  local context_name="$2"
  local interactive="$3"

  if [ ! -f "$src" ]; then
    echo "File not found: $src"
    exit 1
  fi

  echo "Merging config file: $(basename "$src")"
  merge_configs "$src"

  if [[ -n "$context_name" ]]; then
    echo "Renaming default context to '$context_name'"
    kubectl config rename-context default "$context_name" 2>/dev/null || true
  elif [[ "$interactive" == "true" ]]; then
    echo "Available contexts:"
    kubectl config get-contexts
    echo -n "Rename context 'default' to: "
    read -r newname
    if [[ -n "$newname" ]]; then
      echo "Renaming default context to '$newname'"
      kubectl config rename-context default "$newname"
    fi
  fi
}

function switch_context() {
  kubectl config use-context "$1"
}

function backup_restore() {
  local datetime="$1"
  local dir="$BACKUP_ROOT/config.$datetime.bak"
  if [ ! -f "$dir/config.bak" ]; then
    echo "No backup found for $datetime"
    exit 1
  fi
  cp "$dir/config.bak" "$MAIN_CONFIG"
  echo "Restored backup from $datetime"
}

function backup_prune() {
  echo "Pruning backups older than 7 days..."
  find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;
  echo "Old backups pruned."
}

function backup_list() {
  echo "Available backups:"
  if [ -d "$BACKUP_ROOT" ]; then
    find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -name "config.*.bak" | sort | while read -r backup; do
      # Extract the date from the backup folder name
      date_str=$(basename "$backup" | sed 's/config.\(.*\).bak/\1/')
      
      # Format the date in a platform-independent way
      # Try to interpret the timestamp from the backup folder name
      readable_date="$date_str"
      
      # Show year-month-day hour:min:sec from the timestamp if possible
      if [[ "$date_str" =~ ^[0-9]{14}$ ]]; then
        year=${date_str:0:4}
        month=${date_str:4:2}
        day=${date_str:6:2}
        hour=${date_str:8:2}
        minute=${date_str:10:2}
        second=${date_str:12:2}
        readable_date="$year-$month-$day $hour:$minute:$second"
      fi
      
      echo "  $date_str - $readable_date"
    done
  else
    echo "  No backups found."
  fi
}

function delete_context() {
  local context="$1"
  local force="$2"

  if [ "$force" != "--force" ]; then
    read -p "Are you sure you want to delete context '$context'? (y/N): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && exit 1
  fi

  local temp_backup="$(mktemp)"
  cp "$MAIN_CONFIG" "$temp_backup"
  rb "cp '$temp_backup' '$MAIN_CONFIG'; rm -f '$temp_backup'"
  
  kubectl config delete-context "$context" || echo "Context not found"
  
  rm -f "$temp_backup"
}

function rename_context() {
  kubectl config rename-context "$1" "$2"
}

function list_contexts() {
  echo "Available contexts in $MAIN_CONFIG:"
  kubectl config get-contexts
}

# Command dispatcher
case "$1" in
  add)
    shift
    path="$1"
    context="$2"
    flag="$3"
    interactive="false"
    [[ "$flag" == "-i" || "$flag" == "--interactive" ]] && interactive="true"
    add_config "$path" "$context" "$interactive"
    ;;

  switch|use)
    switch_context "$2"
    ;;
  backup-restore)
    backup_restore "$2"
    ;;
  backup-list)
    backup_list
    ;;
  backup-prune)
    backup_prune
    ;;
  delete)
    delete_context "$2" "$3"
    ;;
  rename-context)
    rename_context "$2" "$3"
    ;;
  list)
    list_contexts
    ;;
  -h|--help|help|*)
    usage
    ;;
esac
