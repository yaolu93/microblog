#!/usr/bin/env bash
set -euo pipefail

# Quick dev startup script for this Microblog project
# Usage: ./scripts/run_dev.sh [--no-worker]

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="$BASEDIR/.venv"

mkdir -p "$BASEDIR/logs" "$BASEDIR/tmp"

echo "Base dir: $BASEDIR"

# ensure .env exists (copy from example if available)
if [ ! -f "$BASEDIR/.env" ]; then
  if [ -f "$BASEDIR/.env.example" ]; then
    echo ".env not found, copying .env.example -> .env"
    cp "$BASEDIR/.env.example" "$BASEDIR/.env"
  else
    echo "warning: .env not found and .env.example missing; proceed with defaults"
  fi
fi

if [ ! -d "$VENV_DIR" ]; then
  echo "Creating virtualenv at $VENV_DIR..."
  python3 -m venv "$VENV_DIR"
fi

echo "Activating virtualenv..."
# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"

# Install requirements only when requirements.txt changed to save time on reruns
REQ_FILE="$BASEDIR/requirements.txt"
REQ_SHA_FILE="$VENV_DIR/.requirements_sha"
if [ -f "$REQ_FILE" ]; then
  REQ_SHA=$(sha256sum "$REQ_FILE" | awk '{print $1}')
else
  REQ_SHA=""
fi
PREV_SHA=""
if [ -f "$REQ_SHA_FILE" ]; then
  PREV_SHA=$(cat "$REQ_SHA_FILE")
fi

if [ "$REQ_SHA" != "$PREV_SHA" ]; then
  echo "Installing/updating Python requirements..."
  "$VENV_DIR/bin/python" -m pip install --upgrade pip >/dev/null
  "$VENV_DIR/bin/python" -m pip install -r "$REQ_FILE"
  echo "$REQ_SHA" > "$REQ_SHA_FILE"
else
  echo "Requirements unchanged; skipping pip install"
fi

export FLASK_APP=microblog.py
export FLASK_ENV=development
export FLASK_DEBUG=1

if command -v redis-server >/dev/null 2>&1; then
  if ! pgrep -x redis-server >/dev/null 2>&1; then
    echo "Starting redis-server in background..."
    # start a minimal redis instance (use system redis if you prefer)
    redis-server --save "" --appendonly no &>/dev/null &
    sleep 0.5
  else
    echo "redis-server already running"
  fi
else
  echo "warning: redis-server not found on PATH; using REDIS_URL from environment if set"
fi

echo "Running DB migrations (flask db upgrade)..."
flask db upgrade

echo "Compiling translations (flask translate compile)..."
flask translate compile || true

# parse args: support --no-worker and --force
START_WORKER=true
FORCE_KILL=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-worker)
      START_WORKER=false
      shift
      ;;
    --force)
      FORCE_KILL=true
      shift
      ;;
    *)
      # ignore unknown args
      shift
      ;;
  esac
done

if [ "$START_WORKER" = true ]; then
  echo "Starting RQ worker in background (logs/rq_worker.log)..."
  nohup rq worker microblog-tasks > "$BASEDIR/logs/rq_worker.log" 2>&1 &
  echo $! > "$BASEDIR/tmp/rq_worker.pid"
fi

# helper: find pids listening on port 5000
pids_on_port() {
  local port=5000
  local pids=""
  if command -v lsof >/dev/null 2>&1; then
    pids=$(lsof -ti tcp:${port} || true)
  elif command -v ss >/dev/null 2>&1; then
    # ss output like: users:("/proc/1234/...")
    pids=$(ss -ltnp "sport = :${port}" 2>/dev/null | awk -F"pid=" '/pid=/ {print $2}' | awk -F"," '{print $1}' | tr '\n' ' ')
  else
    # fallback to netstat if available
    if command -v netstat >/dev/null 2>&1; then
      pids=$(netstat -ltnp 2>/dev/null | awk '/:'${port}' / {print $7}' | cut -d'/' -f1 | tr '\n' ' ')
    fi
  fi
  echo "$pids"
}

# check port and optionally kill owner processes
PIDS=$(pids_on_port)
if [ -n "$PIDS" ]; then
  echo "Port 5000 is in use by PID(s): $PIDS"
  for pid in $PIDS; do
    ps -p $pid -o pid,cmd --no-headers || true
  done
  if [ "$FORCE_KILL" = true ]; then
    echo "--force supplied, killing PIDs: $PIDS"
    kill $PIDS || true
    sleep 0.5
    # escalate if still running
    for pid in $PIDS; do
      if kill -0 $pid 2>/dev/null; then
        echo "PID $pid still alive, sending SIGKILL"
        kill -9 $pid || true
      fi
    done
  else
    read -r -p "Kill these processes and free port 5000? [y/N] " answer
    case "$answer" in
      [Yy]*)
        kill $PIDS || true
        sleep 0.5
        for pid in $PIDS; do
          if kill -0 $pid 2>/dev/null; then
            echo "PID $pid still alive, sending SIGKILL"
            kill -9 $pid || true
          fi
        done
        ;;
      *)
        echo "Will not kill processes. Aborting server start."
        exit 1
        ;;
    esac
  fi
fi

echo "Starting Flask development server (flask run)..."
echo "Open http://127.0.0.1:5000"
flask run --host=127.0.0.1 --port=5000
