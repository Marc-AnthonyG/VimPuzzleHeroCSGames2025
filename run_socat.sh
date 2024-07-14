#!/bin/sh

while :; do
    ttyd --writable -p 1337 nvim -u ./init.vim
    sleep 1
done
