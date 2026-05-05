#!/bin/bash
# build-deploy.sh
# Builds ckpool from the currently checked-out branch and deploys binaries
# and config to the specified target directory.
#
# Usage: ./scripts/build-deploy.sh [--noclean] [--yes] <TARGET_DIR>
#
#   <TARGET_DIR>  Directory to deploy binaries and config into (created if needed)
#   --noclean     Skip 'make clean' before building (faster, use on same branch only)
#   --yes         Bypass the branch confirmation prompt

set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
    echo "Error: Not inside a git repository. Run this script from within the ckpool-solo repo."
    exit 1
fi

CLEAN=true
YES=false
TARGET_DIR=""

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --noclean) CLEAN=false ;;
        --yes)     YES=true ;;
        -*)
            echo "Unknown flag: $arg"
            echo "Usage: $0 [--noclean] [--yes] <TARGET_DIR>"
            exit 1
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$arg"
            else
                echo "Unexpected argument: $arg"
                echo "Usage: $0 [--noclean] [--yes] <TARGET_DIR>"
                exit 1
            fi
            ;;
    esac
done

if [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 [--noclean] [--yes] <TARGET_DIR>"
    echo ""
    echo "  <TARGET_DIR>  Directory to deploy binaries and config into (created if needed)"
    echo "  --noclean     Skip 'make clean' before building (faster, use on same branch only)"
    echo "  --yes         Bypass the branch confirmation prompt"
    exit 1
fi

cd "$REPO_ROOT"

# Show current branch and optionally prompt
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "Current branch: $CURRENT_BRANCH"

if [ "$YES" = false ]; then
    read -r -p "Proceed with build from branch '$CURRENT_BRANCH'? (y/N): " answer
    case "$answer" in
        [Yy]) ;;
        *)
            echo "Aborted."
            exit 1
            ;;
    esac
fi

# Run autogen if needed
if [ ! -f configure ]; then
    echo "Running ./autogen.sh ..."
    ./autogen.sh
fi

# Run configure if needed
if [ ! -f Makefile ]; then
    echo "Running ./configure ..."
    ./configure
fi

# Clean
if [ "$CLEAN" = true ]; then
    echo "Running make clean ..."
    make clean
else
    echo "Skipping make clean (--noclean specified)."
fi

# Build
echo "Running make ..."
make

# Verify build output
if [ ! -f src/ckpool ]; then
    echo "Error: src/ckpool not found after build. Build may have failed."
    exit 1
fi

# Create target directory
mkdir -p "$TARGET_DIR"

# Deploy blocknotify script
echo "Deploying blocknotify-multi.sh to $TARGET_DIR/blocknotify-multi.sh ..."
cp scripts/blocknotify-multi.sh "$TARGET_DIR/blocknotify-multi.sh"
chmod +x "$TARGET_DIR/blocknotify-multi.sh"

# Deploy binaries
echo "Deploying binaries to $TARGET_DIR ..."
cp src/ckpool   "$TARGET_DIR/ckpool"
cp src/ckpmsg   "$TARGET_DIR/ckpmsg"
cp src/notifier "$TARGET_DIR/notifier"

# Deploy config (do not overwrite)
if [ -f "$TARGET_DIR/ckpool.conf" ]; then
    echo "Skipping ckpool.conf — file already exists in $TARGET_DIR"
else
    echo "Copying ckpool.conf to $TARGET_DIR ..."
    cp ckpool.conf "$TARGET_DIR/ckpool.conf"
fi

echo ""
echo "Deployment complete."
echo "  Branch:   $CURRENT_BRANCH"
echo "  Binaries: $TARGET_DIR/ckpool, $TARGET_DIR/ckpmsg, $TARGET_DIR/notifier"
echo "  Config:   $TARGET_DIR/ckpool.conf"
echo ""
echo "To start: $TARGET_DIR/ckpool -B -n <name> -c $TARGET_DIR/ckpool.conf"
