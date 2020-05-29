#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd $DIR

rm -f whois.db

ls cache/ | sed 's|^|REBUILD |g' | awk -f whois.awk

popd

