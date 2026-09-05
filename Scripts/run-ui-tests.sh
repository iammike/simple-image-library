#!/bin/bash
#
# Runs the UI test suite against one simulator.
#
# The suite is self-sufficient: the XCUITest runner seeds the photo library with the
# fixture albums and taps the Photos permission alert itself, so a device needs no
# hand preparation. This script exists for the two things a test process cannot do —
# choose and reset the device — and to keep the invocation in the repository rather
# than in someone's shell history.
#
# Usage:
#   Scripts/run-ui-tests.sh                       # default iPhone, reusing its state
#   Scripts/run-ui-tests.sh --fresh               # erase the device first
#   Scripts/run-ui-tests.sh --device "iPad mini (6th generation)" --os 17.2
#   Scripts/run-ui-tests.sh --udid 855D8949-...   # exact device
#
# `--fresh` costs about 90 seconds of erase and boot, and makes the run reproducible
# from nothing. Without it the run reuses a warm device: the photo fixture and the
# permission grant are both already in place, which is roughly 30 seconds faster and
# is the right choice while iterating.

set -euo pipefail

SCHEME="Simple Photo Viewer"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DEVICE="iPhone 15"
OS="17.2"
UDID=""
FRESH=0
EXTRA=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE="$2"; shift 2 ;;
    --os) OS="$2"; shift 2 ;;
    --udid) UDID="$2"; shift 2 ;;
    --fresh) FRESH=1; shift ;;
    *) EXTRA+=("$1"); shift ;;
  esac
done

if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl list devices available -j \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)['devices']
want = '$OS'.replace('.', '-')
for runtime, devices in data.items():
    if not runtime.endswith('iOS-' + want):
        continue
    for device in devices:
        if device['name'] == '''$DEVICE''':
            print(device['udid'])
            raise SystemExit
sys.exit('No available simulator named $DEVICE on iOS $OS')
")
fi

echo "==> Device $UDID ($DEVICE, iOS $OS)"

if [[ "$FRESH" == "1" ]]; then
  echo "==> Erasing"
  xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
  xcrun simctl erase "$UDID"
fi

xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

cd "$PROJECT_DIR"
exec xcodebuild \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$UDID" \
  -only-testing:"Simple Photo ViewerUITests" \
  ${EXTRA[@]+"${EXTRA[@]}"} \
  test
