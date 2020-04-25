#!/usr/bin/env bash

rm -f whois.db

ls cache/ | sed 's|^|REBUILD |g' | awk -f whois.awk


