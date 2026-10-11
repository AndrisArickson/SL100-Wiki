#!/usr/bin/env bash
# Star Legends (SL100) wiki controller.  ./wiki.sh help
set -u
cd "$(dirname "$0")"
PY="${PYTHON:-python3}"
mkdir -p data/logs
LOG=data/logs/crawl.log

running() { [ -f data/crawl.lock ] && kill -0 "$(cat data/crawl.lock 2>/dev/null)" 2>/dev/null; }

case "${1:-help}" in
  topup)      # add newly tagged Legends pages (cheap), then fetch + images + export
    "$PY" tools/crawl.py topup ;;
  start)      # full harvest in the background (resumable; safe to run again)
    if running; then echo "Already running (pid $(cat data/crawl.lock))."; exit 0; fi
    shift; nohup "$PY" tools/crawl.py all "$@" >> "$LOG" 2>&1 &
    echo "Harvest started in background (pid $!). Follow with: ./wiki.sh log" ;;
  pilot)      # small test run: first 200 pages only, then images + placeholders
    "$PY" tools/crawl.py discover && "$PY" tools/crawl.py fetch --limit 200 && "$PY" tools/crawl.py images \
      && "$PY" tools/crawl.py placeholders && "$PY" tools/crawl.py export ;;
  stop)       touch data/STOP; echo "Stop requested; it will finish the current batch and exit." ;;
  status)     running && echo "Crawler: RUNNING (pid $(cat data/crawl.lock))" || echo "Crawler: not running"
              "$PY" tools/crawl.py status ;;
  log)        tail -n 40 -f "$LOG" ;;
  serve)      shift; "$PY" tools/serve.py "$@" ;;
  fts)        "$PY" tools/crawl.py fts ;;
  images)     "$PY" tools/crawl.py images && "$PY" tools/crawl.py placeholders ;;
  export)     "$PY" tools/crawl.py export ;;
  rebuild)    "$PY" tools/crawl.py rebuild ;;   # recreate data/wiki.db from meta/pages.tsv after a git clone
  push)       shift; bash tools/push.sh "$@" ;;
  books)      # d20 source-book extraction / OCR (output: ../Source_Text, outside git)
    shift; sub="${1:-help}"; TXT="../Source_Text"; mkdir -p "$TXT/logs"
    case "$sub" in
      pilot|run)
        if [ -f "$TXT/extract.lock" ] && kill -0 "$(cat "$TXT/extract.lock" 2>/dev/null)" 2>/dev/null; then
          echo "Extraction already running (pid $(cat "$TXT/extract.lock"))."; exit 0; fi
        nohup "$PY" tools/books/extract.py "$@" >> "$TXT/logs/extract.log" 2>&1 &
        echo "Started in background (pid $!). Follow with: ./wiki.sh books log" ;;
      stop)   touch "$TXT/STOP"; echo "Stop requested; finishing in-flight pages. Re-run to resume." ;;
      log)    tail -n 40 -f "$TXT/logs/extract.log" ;;
      catalog) shift; "$PY" tools/books/catalog.py "$@" ;;
      *)      "$PY" tools/books/extract.py "$@" ;;   # status | qa | batches | sample | compare
    esac ;;
  *) cat <<'EOF'
Usage: ./wiki.sh <command>
  start      harvest everything in the background (discover, prioritise, fetch, images, placeholders)
  pilot      quick 200-page test run in the foreground
  stop       stop the background harvest cleanly (progress is kept; 'start' resumes)
  status     progress report
  log        follow the harvest log
  serve [p]  browse/edit the wiki at http://127.0.0.1:8100/
  fts        build full-text search index (run after harvesting)
  images     look up any new image sizes and (re)generate blank webp placeholders
  export     refresh meta/pages.tsv and meta/images.tsv
  rebuild    rebuild the local database from meta/pages.tsv (after cloning the repo)
  books pilot | run --batch N | status | qa | stop | log | compare A B   d20 book extraction/OCR (see docs/)
  push       commit new/changed files in chunks and push to GitHub
EOF
  ;;
esac
