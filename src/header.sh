#!/bin/bash
set -e

VERSION="0.15.0"

# Main dotcontext repo (CLI + Layer 1 templates). Layer 1 = .context/ skeleton,
# CLAUDE.md, .claudeignore, /setup-context.
REPO="goca-se/dotcontext"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

# Marketplace repo (Layer 2 catalog + templates). Split out so community
# contributions to the catalog stay independent of harness changes.
# Overridable via env for power users / community taps / dev work.
MARKETPLACE_REPO="${DOTCONTEXT_MARKETPLACE_REPO:-goca-se/dotcontext-marketplace}"
MARKETPLACE_BRANCH="${DOTCONTEXT_MARKETPLACE_BRANCH:-main}"
MARKETPLACE_URL="https://raw.githubusercontent.com/${MARKETPLACE_REPO}/${MARKETPLACE_BRANCH}"
