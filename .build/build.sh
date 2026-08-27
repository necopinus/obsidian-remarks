#!/usr/bin/env bash
#
# Usage: ./.build/build.sh [clean|serve]
#   (no arg): standard build
#   clean:    remove the cloned Quartz checkout
#   serve:    run `npx quartz build --serve` instead of a one-shot build

set -e

# Make sure npm/npx are available
#
for cmd in npm npx; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "Could not find '$cmd' in your system's PATH!"
		exit 1
	fi
done

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
	exit 0
fi

# Set up the build directory
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
	cd "$SCRIPT_DIR/quartz/content" || exit 1
	# Copy the repo into content/, excluding items that shouldn't end up
	# in the published site.
	#
	tar -cf - -C "$SCRIPT_DIR/.." \
		--exclude='.allowed_signers' \
		--exclude='.build' \
		--exclude='.DS_Store' \
		--exclude='.github' \
		--exclude='.gitignore' \
		--exclude='.keep' \
		--exclude='.nomedia' \
		--exclude='.obsidian' \
		--exclude='.trash' \
		. | tar -xvf -
)

cp -avf ../overlay/* ./

npm install
npx quartz plugin install --from-config

# Build the site!
#
if [[ "$1" == "serve" ]]; then
	npx quartz build --serve
else
	npx quartz build
	# Absolute-ize the RSS feed's relative hrefs/srcs so the published
	# feed points at our hosted site (not the local checkout).
	#
	sed -E 's#(href|src)=\&quot;[\./]+/#\1=\&quot;https://remarks.delphi-strategy.com/#g' \
		./public/index.xml >./public/index.xml.new
	mv ./public/index.xml.new ./public/index.xml
fi
