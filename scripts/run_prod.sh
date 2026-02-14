#!/usr/bin/env bash
set -euo pipefail

# Production startup script for Microblog (simple supervisor-less runner)
# Usage: sudo ./scripts/run_prod.sh

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="${BASEDIR}/venv"

mkdir -p "$BASEDIR/logs" "$BASEDIR/tmp"

echo "Base dir: $BASEDIR"

if [ ! -d "$VENV_DIR" ]; then
  echo "Creating virtualenv at $VENV_DIR..."
  python3 -m venv "$VENV_DIR"
fi

echo "Activating virtualenv..."
# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"

echo "Installing/ensuring requirements..."
pip install --upgrade pip >/dev/null
pip install -r "$BASEDIR/requirements.txt"

export FLASK_APP=microblog.py
export FLASK_ENV=production

if [ -z "${DATABASE_URL:-}" ]; then
  echo "No DATABASE_URL set; using default sqlite in project root"
fi

if command -v redis-server >/dev/null 2>&1; then
  if ! pgrep -x redis-server >/dev/null 2>&1; then
    echo "Starting local redis-server in background..."
    redis-server --save "" --appendonly no &>/dev/null &
    sleep 0.5
  else
    echo "redis-server already running"
  fi
else
  echo "warning: redis-server not found on PATH; ensure REDIS_URL points to a running Redis"
fi

echo "Running DB migrations..."
flask db upgrade

echo "Compiling translations (best-effort)..."
flask translate compile || true

WEB_PORT=${WEB_PORT:-8000}
WEB_WORKERS=${WEB_WORKERS:-4}

echo "Starting gunicorn (port $WEB_PORT, $WEB_WORKERS workers)"
nohup gunicorn -b 0.0.0.0:${WEB_PORT} -w ${WEB_WORKERS} microblog:app > "$BASEDIR/logs/gunicorn.log" 2>&1 &
echo $! > "$BASEDIR/tmp/gunicorn.pid"

echo "Starting RQ worker (background)..."
nohup rq worker microblog-tasks > "$BASEDIR/logs/rq_worker.log" 2>&1 &
echo $! > "$BASEDIR/tmp/rq_worker.pid"

echo "All done. Logs: $BASEDIR/logs"
