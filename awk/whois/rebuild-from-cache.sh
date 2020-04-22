#!/usr/bin/env bash

rm -f whois.db

ls cache/ | awk -f whois.awk


