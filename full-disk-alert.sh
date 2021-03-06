#!/bin/bash
# Tested Under FreeBSD and OS X
FS="/usr"
THRESHOLD=90
OUTPUT=($(LC_ALL=C df -P ${FS}))
CURRENT=$(echo ${OUTPUT[11]} | sed 's/%//')
[ $CURRENT -gt $THRESHOLD ] && echo "$FS file system usage $CURRENT" | mail -s "$FS file system" you@example.com
