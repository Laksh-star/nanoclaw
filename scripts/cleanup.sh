#!/bin/bash
# BizClaw cleanup script
# Removes stale Apple Container artifacts to reclaim disk space.
# Safe to run any time the service is running normally.

set -e

echo "=== BizClaw Cleanup ==="
echo ""

# 1. Remove buildkit container (left over from container builds, ~4-7GB)
if container ls -a 2>/dev/null | grep -q "^buildkit"; then
  echo "Removing buildkit container..."
  container stop buildkit 2>/dev/null || true
  container rm buildkit 2>/dev/null && echo "  buildkit removed."
else
  echo "  buildkit: not present, skipping."
fi

# 2. Remove any stopped (non-running) nanoclaw/bizclaw containers
STOPPED=$(container ls -a 2>/dev/null | awk 'NR>1 && $5 != "running" {print $1}' | grep -v '^$' || true)
if [ -n "$STOPPED" ]; then
  echo "Removing stopped containers..."
  for id in $STOPPED; do
    container rm "$id" 2>/dev/null && echo "  removed: $id"
  done
else
  echo "  stopped containers: none."
fi

# 3. Remove old nanoclaw-agent image if it exists (pre-BizClaw rename)
if container image ls 2>/dev/null | grep -q "nanoclaw-agent"; then
  echo "Removing old nanoclaw-agent image..."
  container image rm nanoclaw-agent:latest 2>/dev/null && echo "  nanoclaw-agent:latest removed."
fi

echo ""
echo "=== Disk Usage After Cleanup ==="
du -sh ~/Library/Application\ Support/com.apple.container/ 2>/dev/null | awk '{print "  Apple Container: " $1}'
du -sh /Users/ln/nanoclaw/data/ 2>/dev/null | awk '{print "  data/:           " $1}'
du -sh /Users/ln/nanoclaw/store/ 2>/dev/null | awk '{print "  store/:          " $1}'

echo ""
echo "Done."
