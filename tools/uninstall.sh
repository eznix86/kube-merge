#!/bin/bash

echo "Uninstalling kube-merge..."

if [[ -n "$ZSH_VERSION" || "$SHELL" =~ "zsh" ]]; then
  shell_rc="$HOME/.zshrc"
elif [[ -n "$BASH_VERSION" || "$SHELL" =~ "bash" ]]; then
  # On macOS, users often use .bash_profile instead of .bashrc
  if [[ "$(uname)" == "Darwin" && -f "$HOME/.bash_profile" && ! -f "$HOME/.bashrc" ]]; then
    shell_rc="$HOME/.bash_profile"
  else
    shell_rc="$HOME/.bashrc"
  fi
else
  shell_rc=""
  echo "Warning: Unsupported shell. You may need to manually remove kube-merge from your shell configuration."
fi

if [[ -n "$shell_rc" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' '/source ~\/.kube-merge\/aliases.sh/d' "$shell_rc"
    sed -i '' '/source ~\/.kube-merge\/autocomplete.sh/d' "$shell_rc"
  else
    sed -i '/source ~\/.kube-merge\/aliases.sh/d' "$shell_rc"
    sed -i '/source ~\/.kube-merge\/autocomplete.sh/d' "$shell_rc"
  fi
  echo "Removed kube-merge from $shell_rc"
fi

echo "Removing kube-merge files..."
rm -rf "$HOME/.kube-merge"

echo "kube-merge has been uninstalled. All of your kubeconfigs were preserved at ~/.kube/config"
echo "Self-removing uninstaller..."
echo "Thank you for using kube-merge!"
rm -f "$0"
