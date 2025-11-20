#!/usr/bin/env zsh
set -e

# Variables
USER_HOME="${1}"
ANTIDOTE_DIR="${USER_HOME}/.antidote"
ZSH_PLUGINS_FILE="${USER_HOME}/.zsh_plugins.sh"
ZSH_STATIC_FILE="${USER_HOME}/.zsh_plugins.zsh"

# Check if antidote is installed
if [[ ! -f "${ANTIDOTE_DIR}/antidote.zsh" ]]; then
    echo "Error: Antidote not found at ${ANTIDOTE_DIR}"
    exit 1
fi

# Source antidote
source "${ANTIDOTE_DIR}/antidote.zsh"

# Update bundles
echo "Updating Antidote bundles..."
antidote update

# Generate static plugins file if needed (though update usually handles this)
if [[ -f "${ZSH_PLUGINS_FILE}" ]]; then
    antidote bundle < "${ZSH_PLUGINS_FILE}" > "${ZSH_STATIC_FILE}"
    echo "Generated static plugins file at ${ZSH_STATIC_FILE}"
fi

echo "Antidote configuration complete."
