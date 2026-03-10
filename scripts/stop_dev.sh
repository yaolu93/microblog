#!/usr/bin/env bash
set -euo pipefail

# Quick dev shutdown script for this Microblog project
# Stops Flask server, RQ worker, and Redis server
# Usage: ./scripts/stop_dev.sh

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="$BASEDIR/.venv"

echo "Stopping Microblog development environment..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to kill process by PID with graceful fallback
kill_process() {
  local pid=$1
  local name=$2
  
  if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
    echo -e "${YELLOW}✓ $name is not running${NC}"
    return 0
  fi
  
  echo -n "Stopping $name (PID: $pid)... "
  if kill "$pid" 2>/dev/null; then
    # Wait max 5 seconds for graceful shutdown
    local count=0
    while kill -0 "$pid" 2>/dev/null && [ $count -lt 5 ]; do
      sleep 0.5
      count=$((count + 1))
    done
    
    # Force kill if still running
    if kill -0 "$pid" 2>/dev/null; then
      echo -n "force killing... "
      kill -9 "$pid" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}done${NC}"
    return 0
  else
    echo -e "${YELLOW}already stopped${NC}"
    return 0
  fi
}

# 1. Stop Flask development server (listening on port 5000)
echo "1. Stopping Flask development server..."
FLASK_PIDS=""
if command -v lsof >/dev/null 2>&1; then
  FLASK_PIDS=$(lsof -ti tcp:5000 || true)
elif command -v ss >/dev/null 2>&1; then
  FLASK_PIDS=$(ss -ltnp "sport = :5000" 2>/dev/null | awk -F"pid=" '/pid=/ {print $2}' | awk -F"," '{print $1}' | tr '\n' ' ' || true)
else
  if command -v netstat >/dev/null 2>&1; then
    FLASK_PIDS=$(netstat -ltnp 2>/dev/null | awk '/:5000 / {print $7}' | cut -d'/' -f1 | tr '\n' ' ' || true)
  fi
fi

if [ -n "$FLASK_PIDS" ]; then
  for pid in $FLASK_PIDS; do
    if [ -n "$pid" ]; then
      kill_process "$pid" "Flask (port 5000)"
    fi
  done
else
  echo -e "${YELLOW}✓ Flask is not running${NC}"
fi

# 2. Stop RQ worker
echo ""
echo "2. Stopping RQ worker..."
RQ_PID_FILE="$BASEDIR/tmp/rq_worker.pid"
if [ -f "$RQ_PID_FILE" ]; then
  RQ_PID=$(cat "$RQ_PID_FILE")
  kill_process "$RQ_PID" "RQ worker"
  rm -f "$RQ_PID_FILE"
else
  # Try to find RQ worker process anyway
  RQ_PID=$(pgrep -f "rq worker" || true)
  if [ -n "$RQ_PID" ]; then
    kill_process "$RQ_PID" "RQ worker"
  else
    echo -e "${YELLOW}✓ RQ worker is not running${NC}"
  fi
fi

# 3. Stop Redis server (only if it was started by the dev script)
echo ""
echo "3. Stopping Redis server..."
if pgrep -x redis-server >/dev/null 2>&1; then
  REDIS_PID=$(pgrep -x redis-server | head -n1)
  read -r -p "Stop Redis server (PID: $REDIS_PID)? [Y/n] " answer
  case "$answer" in
    [Nn]*)
      echo -e "${YELLOW}✓ Redis server left running${NC}"
      ;;
    *)
      kill_process "$REDIS_PID" "Redis server"
      ;;
  esac
else
  echo -e "${YELLOW}✓ Redis server is not running${NC}"
fi

# 4. Deactivate virtual environment (user must do this manually or source script output)
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Development environment stopped${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "If you activated the virtual environment with 'source venv/bin/activate',"
echo "you can deactivate it by running: deactivate"
echo ""
