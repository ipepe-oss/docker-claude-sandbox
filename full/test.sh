#!/bin/bash

set -e

docker stop ubuntu-claude-full-test || true
docker rm ubuntu-claude-full-test || true

docker build . -t ipepe/ubuntu-claude:full-test

# docker run, detach, map port 8080 to 8080, and name the container "ubuntu-claude-full-test"
docker run -d -p 3000:3000 -p 8080:8080 --name ubuntu-claude-full-test ipepe/ubuntu-claude:full-test

docker exec -it ubuntu-claude-full-test bash -c "service --status-all"

docker exec -it ubuntu-claude-full-test bash -c "claude --version"
docker exec -it ubuntu-claude-full-test bash -c "git clone https://github.com/basecamp/fizzy.git ."
#docker exec -it ubuntu-claude-full-test bash -c "asdf install"
docker exec -it ubuntu-claude-full-test bash -c "rbenv install"
docker exec -it ubuntu-claude-full-test bash -c "bundle install"
docker exec -it ubuntu-claude-full-test bash -c "bundle exec rails db:create db:migrate"
docker exec -it ubuntu-claude-full-test bash -c "bundle exec rails test"

