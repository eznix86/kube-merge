# kube-merge

A utility to simplify managing multiple Kubernetes configurations by safely merging them into a single config file.

## Features

- **Simplified Management**: Merge multiple kubeconfig files into your main ~/.kube/config
- **Safe Operations**: Built-in rollback capability via bash-rollback integration
- **Automatic Backups**: Create and restore backups of your configurations
- **Context Management**: Easily switch, rename, and delete contexts
- **Cross-Platform**: Works on Linux, macOS, and Windows (git-bash)
- **Shell Integration**: Includes aliases and tab completion

## Installation

### One-line Install

```bash
curl -sSL https://raw.githubusercontent.com/eznix86/kube-merge/main/install.sh | bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/eznix86/kube-merge/main/install.sh | bash
```

This will:
- Install kube-merge to `~/.kube-merge/`
- Set up shell aliases and autocompletion
- Create necessary backup directories

### Uninstallation

```bash
kube-merge-uninstall
```

## Commands

```bash
# Add a new kubeconfig file
km add <path-to-kubeconfig> [new-context-name] [-i|--interactive]

# Switch to a specific context
km switch <context-name>
km use <context-name>

# Restore from a specific backup
km backup-restore <datetime>

# List all available backups with timestamps
km backup-list

# Clean up old backups (older than 7 days)
km backup-prune

# Delete a specific context
km delete <context-name> [--force]

# Rename a specific context
km rename-context <old> <new>

# List all available contexts
km list

# Show help
km [-h|--help]
```

## Examples

### Adding a new kubeconfig

```bash
# Basic usage - add a config file
km add ~/Downloads/cluster-config.yaml

# Add with a custom context name
km add ~/Downloads/eks-cluster.yaml eks-prod

# Add interactively (prompts to rename context)
km add ~/Downloads/gke-cluster.yaml -i
```

### Managing contexts

```bash
# List all available contexts
km list

# Switch to a specific context
km switch production-cluster

# Rename a context
km rename-context old-name new-name

# Delete a context (with confirmation)
km delete dev-context

# Delete a context without confirmation
km delete dev-context --force
```

### Backup Operations

```bash
# List all available backups with timestamps
km backup-list

# Restore from a specific backup
km backup-restore 20250506120000

# Clean up old backups (older than 7 days)
km backup-prune
```

## Security

kube-merge sets proper permissions (chmod 600) on your kubeconfig files and never exposes sensitive information.
