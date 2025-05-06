#!/bin/bash

set -e

echo "Installing kube-merge..."

INSTALL_DIR="$HOME/.kube-merge"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/configs"
mkdir -p "$INSTALL_DIR/backups"

echo "Downloading kube-merge..."
curl -sSL https://raw.githubusercontent.com/eznix86/kube-merge/main/kube-merge.sh -o "$INSTALL_DIR/kube-merge"
chmod +x "$INSTALL_DIR/kube-merge"

echo "Setting up uninstaller..."
curl -sSL https://raw.githubusercontent.com/eznix86/kube-merge/main/tools/uninstall.sh -o "$INSTALL_DIR/kube-merge-uninstall"
chmod +x "$INSTALL_DIR/kube-merge-uninstall"

echo "Setting up shell configuration..."

if [[ -n "$ZSH_VERSION" || "$SHELL" =~ "zsh" ]]; then
  shell_rc="$HOME/.zshrc"
elif [[ -n "$BASH_VERSION" || "$SHELL" =~ "bash" ]]; then
  if [[ "$(uname)" == "Darwin" && -f "$HOME/.bash_profile" && ! -f "$HOME/.bashrc" ]]; then
    shell_rc="$HOME/.bash_profile"
  else
    shell_rc="$HOME/.bashrc"
  fi
else
  echo "Unsupported shell. Only Bash and Zsh are automatically configured."
  echo "Please manually add 'alias km=$INSTALL_DIR/kube-merge' to your shell configuration."
  exit 1
fi

echo "Setting up shell integration..."
curl -sSL https://raw.githubusercontent.com/eznix86/kube-merge/main/tools/aliases.sh -o "$INSTALL_DIR/aliases.sh"
curl -sSL https://raw.githubusercontent.com/eznix86/kube-merge/main/tools/autocomplete.sh -o "$INSTALL_DIR/autocomplete.sh"
if ! grep -q "source ~/.kube-merge/aliases.sh" "$shell_rc"; then
  echo "source ~/.kube-merge/aliases.sh" >> "$shell_rc"
fi

if ! grep -q "source ~/.kube-merge/autocomplete.sh" "$shell_rc"; then
  echo "source ~/.kube-merge/autocomplete.sh" >> "$shell_rc"
fi

echo "kube-merge installed successfully!"
echo "Please restart your shell or run: source $shell_rc"
echo "You can now use the 'km' command to manage your Kubernetes configurations."
echo "To uninstall, run: kube-merge-uninstall"
