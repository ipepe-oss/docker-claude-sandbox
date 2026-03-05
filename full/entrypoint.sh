#!/bin/bash

service postgresql start &
service redis-server start

wait

service --status-all

# TODO: `asdf install` when we move from rbenv to asdf

if [ "${1}" == "gottyautostart" ]; then
  gotty tmux new -A -s gotty bash
fi

exec "${@}"
