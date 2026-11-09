#!/usr/bin/env bash
set -e
# Project-Files — docs-only as inspected 2026-11-09.
# Only file found: README.md (15 bytes) containing just "# Project-Files".
# Verify-and-open script: no build exists to run, so none is invented.
# Bootstrap: on a fresh Ubuntu/Debian VM this installs its own base
# prerequisites (git, curl) via apt before cloning — nothing else is
# needed for a docs-only repo.

REPO="Project-Files"
OWNER="UncleD0886475978"
URL="https://github.com/${OWNER}/${REPO}.git"
DEST="$HOME/repos/${REPO}"
RUN_ONELINE="curl -fsSL https://raw.githubusercontent.com/${OWNER}/${REPO}/main/setup.sh | bash"

if [ -f "$0" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
  SCRIPT_DIR="$PWD"
fi

echo "==> Step 1/5: Platform check + base bootstrap (git, curl)"
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "ERROR: this script needs root or sudo to install packages."
    exit 1
  fi
fi
APT=0
if [ "$(uname -s)" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then APT=1; fi
INSTALLED=""
APT_UPDATED=""
note_installed() { INSTALLED="${INSTALLED} $1"; }
apt_update_once() {
  if [ -z "${APT_UPDATED}" ]; then $SUDO apt-get update -y; APT_UPDATED=1; fi
}
apt_install() {
  apt_update_once
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "$@"
}
ensure_apt_pkg() { # ensure_apt_pkg <command> <package>
  if command -v "$1" >/dev/null 2>&1; then echo "    $1: already present"; return 0; fi
  [ "${APT}" -eq 1 ] || return 1
  echo "    Installing $2..."
  apt_install "$2"
  note_installed "$2"
}
if [ "${APT}" -eq 1 ]; then
  BASE_PKGS=""
  command -v git >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} git"
  command -v curl >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} curl"
  [ -f /etc/ssl/certs/ca-certificates.crt ] || BASE_PKGS="${BASE_PKGS} ca-certificates"
  command -v gpg >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} gnupg"
  if [ -n "${BASE_PKGS}" ]; then
    echo "    Installing base tools:${BASE_PKGS}"
    # shellcheck disable=SC2086
    apt_install ${BASE_PKGS}
    note_installed "${BASE_PKGS}"
  else
    echo "    Base tools already present (git, curl, ca-certificates, gnupg)."
  fi
else
  echo "    Non-apt platform detected — bootstrap will only CHECK tools and print install guidance."
fi

echo "==> Step 2/5: Get the repo"
if ! command -v git >/dev/null 2>&1; then
  echo "git not found. Install it: https://git-scm.com/downloads"
  exit 0
fi
echo "git: $(git --version)"
if [ -f ".git/config" ] && grep -q "${REPO}" .git/config 2>/dev/null; then
  echo "Already inside a ${REPO} checkout: $(pwd)"
  DEST="$(pwd)"
elif [ -d "${DEST}/.git" ]; then
  echo "Found existing checkout at ${DEST} — pulling"
  git -C "${DEST}" pull --ff-only
else
  echo "Cloning ${URL} into ${DEST}"
  mkdir -p "$HOME/repos"
  git clone "${URL}" "${DEST}"
fi
cd "${DEST}"
REPO_DIR="${DEST}"

echo "==> Step 3/5: Bootstrap prerequisites"
# Docs-only repo: base tools (git, curl) are the only prerequisites.
# They were installed in Step 1 on apt systems; on non-apt systems,
# fall back to checking and printing guidance.
MISSING_LIST=""
if ! command -v git >/dev/null 2>&1; then
  MISSING_LIST="${MISSING_LIST} git(https://git-scm.com/downloads)"
fi
if [ -n "${MISSING_LIST}" ]; then
  echo "ERROR: could not auto-install on this platform. Missing:${MISSING_LIST}"
  echo "Install the tool(s) manually, then re-run this script."
  exit 1
fi
echo "    Prerequisites OK — docs-only repo, no build tools needed."

echo "==> Step 4/5: Verify and list key docs"
echo "All files (excluding .git):"
find . -path ./.git -prune -o -type f -print | sort
echo ""
echo "Key docs:"
for f in README.md; do
  if [ -f "${f}" ]; then
    echo "--- ${f}: $(head -n 1 "${f}")"
  else
    echo "--- ${f}: MISSING"
  fi
done

echo "==> Step 5/5: Open the README"
if [ -f README.md ]; then cat README.md; else echo "No README.md found."; fi
echo ""
echo "This repo currently holds only that one-line README — there is no code,"
echo "config, or build step. Add project files, push, and re-run to verify."

cat <<EOF

=================== BOOTSTRAP SUMMARY ===================
Installed during this run:${INSTALLED:- (nothing — all tools were already present)}
Working copy: ${REPO_DIR}
Next time, set up from scratch on any fresh Ubuntu VM with one line:
  ${RUN_ONELINE}
=========================================================
EOF

echo ""
echo "Next commands:"
echo "  cd ${DEST}"
echo "  ls -la"
echo "  cat README.md"
echo "  git log --oneline -5"
