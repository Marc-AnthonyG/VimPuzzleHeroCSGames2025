#!/bin/sh

while :; do
    ttyd --writable -p 1337 nvim -V20/tmp/nvim_debug.log
    sleep 1
done
