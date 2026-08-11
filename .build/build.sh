#!/usr/bin/env bash

set -e

# Make sure npm/npx are available
#
if [[ -z "$(which npm 2> /dev/null)" ]]; then
	echo "Could not find 'npm' in your system's PATH!"
	exit 1
fi

if [[ -z "$(which npx 2> /dev/null)" ]]; then
	echo "Could not find 'npx' in your system's PATH!"
	exit 1
fi

# Switch to this script's directory
#
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -d "$SCRIPT_DIR/../.git" ]] || [[ ! -d "$SCRIPT_DIR/overlay" ]]; then
	echo "Script runtime directory validation failed!"
	exit 1
fi

cd "$SCRIPT_DIR" || exit 1

# Clean build directory and exit if instructed to do so
#
if [[ "$1" == "clean" ]]; then
	if [[ -e quartz ]]; then
		rm -rf quartz
	fi
	exit
fi

# Set up the build directory.
#
if [[ ! -d quartz ]]; then
	if [[ -e quartz ]]; then
		rm -rf quartz
	fi
	git clone https://github.com/jackyzha0/quartz.git
	(
		cd quartz || exit 1
		git checkout v5
	)
fi

cd quartz || exit 1

(
	cd content || exit 1
	tar -cf - -C ../../../ \
	        --exclude='.build' \
	        --exclude='.DS_Store' \
	        --exclude='.git' \
	        --exclude='.gitignore' \
	        --exclude='.nomedia' \
	        --exclude='.obsidian' \
	        --exclude='.trash' \
	                  . | tar -xf -
)

cp -af ../overlay/* ./

npm install
npx quartz plugin install --from-config

# Build the site!
#
if [[ "$1" == "serve" ]]; then
	npx quartz build --serve
else
	npx quartz build
fi
