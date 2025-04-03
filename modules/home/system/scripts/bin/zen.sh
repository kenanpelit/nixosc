#!/usr/bin/env bash

# Zen Browser Wrapper Script
# -------------------------------------------------------------------------
# This script serves as a wrapper for the zen-beta command, allowing
# the user to simply type 'zen' instead of 'zen-beta' to launch the browser.
# It forwards all arguments to the zen-beta command.
# -------------------------------------------------------------------------

# Check if zen-beta is available in the PATH
if ! command -v zen-beta &>/dev/null; then
	echo "Error: zen-beta command not found in PATH"
	echo "Please ensure Zen Browser is properly installed"
	exit 1
fi

# Execute zen-beta with all passed arguments
exec zen-beta "$@"
