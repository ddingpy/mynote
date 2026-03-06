#!/bin/sh
set -eu

cd /srv/jekyll

jekyll build --watch --force_polling --config _config.yml,_config.dev.yml &
JEKYLL_PID=$!

cleanup() {
  kill "$JEKYLL_PID" 2>/dev/null || true
}

trap cleanup INT TERM EXIT

node /srv/jekyll/scripts/static-server.js /srv/jekyll/_site 4000
