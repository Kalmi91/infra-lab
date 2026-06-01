#!/usr/bin/env bash
# Installs the infra-lab toolchain into ~/.local/bin and makes sure Docker is
# usable. Run this once, on the HOST shell (not inside the Claude Code sandbox —
# it needs the Docker daemon and real sudo).
#
#   ./scripts/bootstrap.sh
#
# Idempotent: skips anything already installed.
set -euo pipefail

BIN="${HOME}/.local/bin"
mkdir -p "$BIN"
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "WARNING: $BIN is not on your PATH. Add it to ~/.bashrc:"
     echo '  export PATH="$HOME/.local/bin:$PATH"' ;;
esac

TF_VERSION="1.10.5"
KIND_VERSION="v0.27.0"
K6_VERSION="v0.57.0"

have() { command -v "$1" >/dev/null 2>&1; }

# --- Terraform ---------------------------------------------------------------
if have terraform; then
  echo "terraform: present ($(terraform version | head -1))"
else
  echo "terraform: installing ${TF_VERSION}"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/tf.zip" \
    "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
  unzip -o "$tmp/tf.zip" -d "$BIN" >/dev/null
  rm -rf "$tmp"
fi

# --- kubectl -----------------------------------------------------------------
if have kubectl; then
  echo "kubectl: present"
else
  echo "kubectl: installing latest stable"
  ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o "$BIN/kubectl" "https://dl.k8s.io/release/${ver}/bin/linux/amd64/kubectl"
  chmod +x "$BIN/kubectl"
fi

# --- kind --------------------------------------------------------------------
if have kind; then
  echo "kind: present"
else
  echo "kind: installing ${KIND_VERSION}"
  curl -fsSL -o "$BIN/kind" \
    "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
  chmod +x "$BIN/kind"
fi

# --- k6 ----------------------------------------------------------------------
if have k6; then
  echo "k6: present"
else
  echo "k6: installing ${K6_VERSION}"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/k6.tar.gz" \
    "https://github.com/grafana/k6/releases/download/${K6_VERSION}/k6-${K6_VERSION}-linux-amd64.tar.gz"
  tar -xzf "$tmp/k6.tar.gz" -C "$tmp"
  cp "$tmp"/k6-*/k6 "$BIN/k6"
  chmod +x "$BIN/k6"
  rm -rf "$tmp"
fi

# --- LocalStack + awslocal (pip) --------------------------------------------
if have localstack; then
  echo "localstack: present"
else
  echo "localstack: installing via pip"
  pip install --user --quiet localstack awscli-local
fi

# --- Docker daemon -----------------------------------------------------------
if docker ps >/dev/null 2>&1; then
  echo "docker: daemon reachable"
else
  echo "docker: starting daemon (needs sudo)"
  sudo systemctl start docker || sudo service docker start
  if ! id -nG "$USER" | grep -qw docker; then
    echo "docker: adding $USER to the docker group (log out/in afterwards)"
    sudo usermod -aG docker "$USER"
    echo "  --> run 'newgrp docker' or re-login, then re-run this script"
  fi
fi

echo
echo "bootstrap done. Versions:"
for t in terraform kubectl kind k6 localstack; do
  have "$t" && printf '  %-11s %s\n' "$t" "$($t version 2>/dev/null | head -1)"
done
