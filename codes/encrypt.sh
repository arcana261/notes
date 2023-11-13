#!/usr/bin/env bash

echo 'Mothers first name (all lower, like "sarah")?'
read mother

echo 'Fathers last name (all lower, like "john")?'
read father

echo 'First teachers name (all lower, like "nash")?'
read teacher

echo 'Cats name (all lower, hint: starts with "m", like "porter")?'
read cat

echo 'Birthday (YYYYmmdd format, like "20231121")?'
read birthday

echo 'Grandfathers first name (all lower, hint: starts with "hou")?'
read grandfather

echo 'Simple password (hint: dream)?'
read simplepass

password="$mother:$father:$teacher:$cat:$birthday:$grandfather:$simplepass"

cat codes-unencrypted.txt | openssl aes-256-cbc -a -salt -pass pass:$password > codes.txt


