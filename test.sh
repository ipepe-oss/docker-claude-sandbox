#!/bin/bash

set -e

docker stop ubuntu-claude-full-test || true
docker rm ubuntu-claude-full-test || true

docker build . -t ipepe/ubuntu-claude:full-test

# docker run, detach, map port 7681 to 7681, and name the container "ubuntu-claude-full-test"
docker run -d -p 7683:7681 --name ubuntu-claude-full-test ipepe/ubuntu-claude:full-test

docker exec -i ubuntu-claude-full-test bash -c "service --status-all"

echo "/root/.tmux.conf is:"
docker exec -i ubuntu-claude-full-test bash -c "cat /root/.tmux.conf"

docker exec -i ubuntu-claude-full-test bash -c "claude --version"
docker exec -i ubuntu-claude-full-test bash -c "git clone https://github.com/basecamp/fizzy.git ."
docker exec -i ubuntu-claude-full-test bash -c "asdf install"
docker exec -i ubuntu-claude-full-test bash -c "apt-get update && apt-get install -y libvips42"
docker exec -i ubuntu-claude-full-test bash -c "bundle install"
docker exec -i ubuntu-claude-full-test bash -c "bundle exec rails db:create db:migrate"
docker exec -i ubuntu-claude-full-test bash -c "bundle exec rails test"

docker stop ubuntu-claude-full-test || true
docker rm ubuntu-claude-full-test || true
