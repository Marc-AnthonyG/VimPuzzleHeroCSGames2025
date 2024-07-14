#!/bin/sh

while :; do
    socat -dd -T1800 tcp-l:1337,reuseaddr,fork,keepalive exec:"nvim -u ./init.vim",pty,stderr
done
