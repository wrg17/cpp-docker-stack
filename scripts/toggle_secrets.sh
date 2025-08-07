#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SECRETS_DIR="$ROOT_DIR/secrets"

KEY_FILE="$SECRETS_DIR/key.txt"
[[ -f $KEY_FILE ]] || { echo "❌ $KEY_FILE not found" >&2; exit 1; }

SOPS_CFG="$SECRETS_DIR/.sops.yaml"
[[ -f $SOPS_CFG ]] || { echo "❌ $SOPS_CFG not found" >&2; exit 1; }

relative_to_root() {
  local some_path="$1"
  realpath --relative-to="${ROOT_DIR}" "${some_path}"
}

usage() {
  echo "Usage: $(basename "$0") [encrypt|decrypt]" >&2
  exit 1
}

encrypt_all() {
  shopt -s nullglob dotglob
  local found=false
  for dec in "$SECRETS_DIR"/*.dec*; do
    [[ -e "$dec" ]] || continue
    found=true
    local enc="${dec/.dec/.enc}"
    printf "🔐 Encrypting %s\t-> %s\n" "$(relative_to_root "$dec")" "$(relative_to_root "$enc")"
    SOPS_AGE_KEY_FILE="$KEY_FILE" \
      sops -e --config "$SOPS_CFG" --output "$enc" "$dec"
    shred -u "$dec"
  done
  shopt -u nullglob dotglob
  $found || echo "💡 Nothing to encrypt (no *.dec files)."
}

decrypt_all() {
  shopt -s nullglob dotglob
  local found=false
  for enc in "$SECRETS_DIR"/*.enc*; do
    [[ -e "$enc" ]] || continue
    found=true
    local dec="${enc/.enc/.dec}"
    printf "🔓 Decrypting %s\t-> %s\n" "$(relative_to_root "$enc")" "$(relative_to_root "$dec")"
    SOPS_AGE_KEY_FILE="$KEY_FILE" \
      sops -d --config "$SOPS_CFG" "$enc" > "$dec"
  done
  shopt -u nullglob dotglob
  $found || echo "💡 Nothing to decrypt (no *.enc files)."
}

MODE="${1:-auto}"
case "$MODE" in
  encrypt) encrypt_all ; echo "✅  Encryption complete. Plaintext removed." ;;
  decrypt) decrypt_all ; echo "✅  Decryption complete. Plaintext ready." ;;
  help) usage ;;
  *)
    if find secrets/ -maxdepth 1 -name "*.dec*" -print -quit | grep -q .; then
      encrypt_all
      echo "✅  Auto‑mode: encrypted & shredded plaintext."
    elif find secrets/ -maxdepth 1 -name "*.enc*" -print -quit | grep -q .; then
      decrypt_all
      echo "✅  Auto‑mode: decrypted secrets ready."
    else
      echo "💡 No secrets found to encrypt or decrypt."
    fi
    ;;
esac
