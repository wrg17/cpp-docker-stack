#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SECRETS_DIR="${ROOT_DIR}/secrets"

SOPS_CFG="${SECRETS_DIR}/.sops.yaml"
KEY_FILE="${SECRETS_DIR}/key.txt"

relative_to_root() {
  local some_path="$1"
  realpath --relative-to="${ROOT_DIR}" "${some_path}"
}

brew_update() {
  echo "🔄 Updating Homebrew..."
  brew update --quiet
}

ensure_formula() {
  local pkg=$1
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    echo "✅  $pkg already installed."
  else
    echo "⬇️  Installing $pkg..."
    brew install "$pkg"
  fi
}

ensure_cask() {
  local cask=$1
  if brew list --cask "$cask" >/dev/null 2>&1; then
    echo "✅  $cask already installed."
  else
    echo "⬇️  Installing $cask…"
    brew install --cask "$cask"
  fi
}

install_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "❌ Homebrew not found." >&2;
    exit 1;
  fi

  brew_update

  for pkg in age sops yq; do
    ensure_formula "$pkg"
  done

  if ! command -v docker >/dev/null 2>&1; then
    ensure_cask docker
    open -a Docker

    echo "🐳 Waiting for Docker to start..."
    until docker system info >/dev/null 2>&1; do sleep 1; done
  else
    echo "🐳 Docker CLI already available."
  fi

  echo "🍎 Mac setup complete!"
  echo
}

inject_public_key() {
  local key_file="$1"
  local pubkey
  pubkey=$(grep '^# public key:' "${key_file}" | awk '{print $4}')

  if [[ -z "${pubkey}" ]]; then
    echo "❌ Could not find public key in $(relative_to_root "${key_file}")" >&2; exit 1
  fi

  if [[ ! -f "${SOPS_CFG}" ]]; then
    echo "❌ Key file not found at $(relative_to_root "${key_file}")" >&2; exit 1
  fi

  yq eval '(.creation_rules[] | select(.age)) |= del(.age)' -i "${SOPS_CFG}"
  yq eval "(.creation_rules[0].age) = \"${pubkey}\"" -i "${SOPS_CFG}"

  echo "      Updated -> '$(relative_to_root "${SOPS_CFG}")'."
  echo
}

initialize_secrets() {
  echo "🔐 Initializing secrets..."

  local valid_envs=("int" "dev" "prod")
  local secrets=("postgres_password")

  for secret in "${secrets[@]}"; do
    echo "   🔨 Creating '${secret}'"
    for env in "${valid_envs[@]}"; do
      printf "      '%s':\t" "${env}"
      local enc_file="${SECRETS_DIR}/.${env}.${secret}.secrets.enc"
      local dec_file="${SECRETS_DIR}/.${env}.${secret}.secrets.dec"

      if [[ ! -f "${dec_file}" ]]; then
        openssl rand -base64 32 > "${dec_file}"

        SOPS_AGE_KEY_FILE="${KEY_FILE}" \
          sops -e --config "${SOPS_CFG}" --output "${enc_file}" "${dec_file}"

        shred "${dec_file}"
        echo "'$(relative_to_root "${dec_file}")'."
      else
        echo "Already exists, skipping."
      fi
    done
    echo
  done
  echo "🔑 Secrets initialization complete."
}

OS="$(uname -s)"
case "${OS}" in
  Darwin*)
    echo "🍎 Running Mac setup"
    install_macos
    ;;
  *)
    echo "Unsupported OS: ${OS}" >&2
    exit 1
    ;;
esac

if [[ ! -f "${KEY_FILE}" ]]; then
  echo "🔑 Generating project AGE key → $(relative_to_root "${KEY_FILE}")"
  age-keygen -o "${KEY_FILE}" > /dev/null

  PUBLIC_KEY=$(grep '^# public key:' "${KEY_FILE}" | awk '{print $4}')
  echo "   🔑 Public key: ${PUBLIC_KEY}"

  inject_public_key "${KEY_FILE}"
else
  echo "💡 Found existing AGE key at $(relative_to_root "${KEY_FILE}")"
fi

initialize_secrets
