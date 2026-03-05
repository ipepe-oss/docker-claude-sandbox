#!/bin/bash

service postgresql start &
service redis-server start

wait

service --status-all

asdf install 2>/dev/null || true

if [ "${1}" == "gottyautostart" ]; then
  gotty tmux new -A -s gotty bash
fi

exec "${@}"
