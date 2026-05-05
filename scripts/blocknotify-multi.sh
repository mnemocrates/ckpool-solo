#!/bin/bash
# blocknotify-multi.sh
# Wrapper script for bitcoind's -blocknotify option when multiple ckpool
# instances are running on the same host, all sharing the same bitcoind.
#
# Each entry below calls the notifier binary with the -n flag matching the
# name used when ckpool was started (via its -n flag).  Add or remove lines
# to match the instances you have running.
#
# Usage in bitcoin.conf:
#   blocknotify=/path/to/blocknotify-multi.sh
#
# Options accepted by the notifier binary:
#   -n NAME    Instance name (must match the -n flag used to start ckpool).
#              Determines the Unix socket path: /tmp/{NAME}/stratifier
#              Defaults to "ckpool" if omitted.
#   -s DIR     Socket base directory override (must match ckpool's -s flag).
#              Defaults to /tmp if omitted.
#   -p         Proxy mode (use "ckproxy" as the default name instead of "ckpool").
#
# The notifier binary must be on PATH or specify an absolute path.
# Each notifier call is independent; failure of one does not stop the others.
# ---------------------------------------------------------------------------

set -euo pipefail

NOTIFIER="${NOTIFIER:-notifier}"

# ---------------------------------------------------------------------------
# List one line per ckpool instance.
# Adjust -n values to match your ckpool -n startup flags.
# ---------------------------------------------------------------------------

"$NOTIFIER" -n ckpool-lhr   || true
"$NOTIFIER" -n ckpool-std   || true

# Example: instance started with a custom socket directory (-s /var/run/ckpool)
# "$NOTIFIER" -n ckpool-lhr -s /var/run/ckpool || true
