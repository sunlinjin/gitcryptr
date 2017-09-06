#!/usr/bin/env bash

#####
# ./gitcryptr <password> <git-repo-link>
# Inspired by https://gist.github.com/shadowhand/873637
#####

if [[ $# -ne 2 ]] ; then
    echo "Usage: $0 <password> <git-repo-link>"
    exit 0
fi

if [[ $EUID -eq 0 ]]; then
   echo "WARNING: INITIALISING WITH ROOT PRIV" 1>&2
fi

echo "                   .__  __                               __           "
echo "              ____ |__|/  |_  ___________ ___.__._______/  |________  "
echo "             / ___\|  \   __\/ ___\_  __ <   |  |\____ \   __\_  __ \ "
echo "            / /_/  >  ||  | \  \___|  | \/\___  ||  |_> >  |  |  | \/ "
echo "            \___  /|__||__|  \___  >__|   / ____||   __/|__|  |__|    "
echo "           /_____/               \/       \/     |__|  t : @kh4st3x   "
echo ""
echo ""


#####
# Init User configs.
# Salt is random 12 hex character alphanumeric string (lowercase only).
#####
#INIT_SALT=$(cat /dev/urandom | tr -dc 'a-fA-F0-9' | fold -w 12 | head -n 1)
INIT_SALT='AFdFb9ABD1Fe'
echo "Generated following salt : $INIT_SALT"
echo ""

INIT_PASS=$1
GIT_URL=$2

mkdir ".gitcryptr"
cd ".gitcryptr"

#####
# Create clean_filter_openssl file AKA encryption.
# Using ECB encryption to keep timestamps.
# Change to CBC for stronger encryption, but recreates file at every smudge.
#####
echo "#!/bin/bash" > clean_filter_openssl
echo "SALT_FIXED=$INIT_SALT" >> clean_filter_openssl
echo "PASS_FIXED=$INIT_PASS" >> clean_filter_openssl
echo "openssl enc -base64 -aes-256-ecb -S \$SALT_FIXED -k \$PASS_FIXED" >> clean_filter_openssl

#####
# Create smudge_filter_openssl AKA decryption
# Salt is not required for decryption
#####
echo "#!/bin/bash" > smudge_filter_openssl
echo "" >> smudge_filter_openssl
echo "# No salt is needed for decryption" >> smudge_filter_openssl
echo "PASS_FIXED=$INIT_PASS" >> smudge_filter_openssl
echo "" >> smudge_filter_openssl
echo "# If decryption fails, use cat instead." >> smudge_filter_openssl
echo "# Error messages are redirected to /dev/null." >> smudge_filter_openssl
echo "openssl enc -d -base64 -aes-256-ecb -k \$PASS_FIXED 2> /dev/null || cat" >> smudge_filter_openssl

#####
# Create diff_filter_openssl
# Decryption only, no salt needed
#####
echo "#!/bin/bash" > diff_filter_openssl
echo "" >> diff_filter_openssl
echo "# No salt is needed for decryption." >> diff_filter_openssl
echo "PASS_FIXED=$INIT_PASS" >> diff_filter_openssl
echo "" >> diff_filter_openssl
echo "# Error messages are redirect to /dev/null." >> diff_filter_openssl
echo "openssl enc -d -base64 -aes-256-ecb -k \$PASS_FIXED -in "\$1" 2> /dev/null || cat "\$1"" >> diff_filter_openssl

#####
# Link up to remote git
#####
cd ..
chmod "-R" "+rx" ".gitcryptr/"
echo "gitcryptr : If you're seeing this message from the git server something went wrong" > README.md
git init
git remote add origin $GIT_URL

#####
# Create .gitattributes defining commit filters
#####
echo "* filter=openssl diff=openssl" > .gitattributes
echo "[merge]" >> .gitattributes
echo "    renormalize=true" >> .gitattributes

#####
# Update local git config file with filter specifications
#####
echo "[filter \"openssl\"]" >> .git/config
echo "    smudge = `pwd`/.gitcryptr/smudge_filter_openssl" >> .git/config
echo "    clean = `pwd`/.gitcryptr/clean_filter_openssl" >> .git/config
echo "[diff \"openssl\"]" >> .git/config
echo "    textconv = `pwd`/.gitcryptr/diff_filter_openssl" >> .git/config

#####
# Exclude files to ensure not pushing password or script
#####
echo ""
echo "-- Excluding encryption configuration from git repository"
echo ""
echo ".gitcryptr/*" > .git/info/exclude
echo "gitcryptr.sh" >> .git/info/exclude

#####
# Finish up and push README to master branch
#####
git add README.md
git commit -m "Initial gitcryptr commit"
git push -u origin master

echo "--------"
echo "gitcryptr is done. Clean your shell history"
echo "--------"
echo ""
