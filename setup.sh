#!/usr/bin/env bash
set -e
# Project-Files — docs-only as inspected 2026-11-09.
# Only file found: README.md (15 bytes) containing just "# Project-Files".
# Verify-and-open script: no build exists to run, so none is invented.

REPO="Project-Files"
OWNER="UncleD0886475978"
URL="https://github.com/${OWNER}/${REPO}.git"
DEST="$HOME/repos/${REPO}"

echo "==> Step 1/4: Check prerequisites"
if ! command -v git >/dev/null 2>&1; then
  echo "git not found. Install it: https://git-scm.com/downloads"
  exit 0
fi
echo "git: $(git --version)"

echo "==> Step 2/4: Get the repo"
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

echo "==> Step 3/4: Verify and list key docs"
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

echo "==> Step 4/4: Open the README"
if [ -f README.md ]; then cat README.md; else echo "No README.md found."; fi
echo ""
echo "This repo currently holds only that one-line README — there is no code,"
echo "config, or build step. Add project files, push, and re-run to verify."

echo ""
echo "Next commands:"
echo "  cd ${DEST}"
echo "  ls -la"
echo "  cat README.md"
echo "  git log --oneline -5"
