#!/bin/sh

mkdir -p ~/.local/share/nvim
touch ~/.local/share/nvim/VimMasterChallenge.log

tail -f ~/.local/share/nvim/VimMasterChallenge.log &

while :; do
  ttyd --writable -p 1337 nvim -V20/tmp/nvim_debug.log
  sleep 1
done
