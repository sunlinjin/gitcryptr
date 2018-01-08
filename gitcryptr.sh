#!/usr/bin/env bash

#####
# ./gitcryptr <password> <git-repo-link>
# updated base on git@github.com:khast3x/gitcryptr.git
#####

# openssl smime -encrypt -aes256 -binary -outform DEM -in "$LEAFTMP" -out "$ROOTREPO" "$GITPUBLIC"
# openssl smime -decrypt -binary -inform DEM -inkey "$GITPRIVATE" -in "$ROOTREPO" -out "$LEAFTMP"

WorkingDir="$(pwd)"
PrivateKey=${WorkingDir}/RSA_Private
PublicKey=${WorkingDir}/RSA_Public
if [ ! -s "$PublicKey" ];then
    echo "-----BEGIN CERTIFICATE-----
MIIC1TCCAb2gAwIBAgIJAOu4V9Pmcu1iMA0GCSqGSIb3DQEBCwUAMAAwIBcNMTYx
MDA2MDI1MjIxWhgPMjI5MDA3MjIwMjUyMjFaMAAwggEiMA0GCSqGSIb3DQEBAQUA
A4IBDwAwggEKAoIBAQC22nY3Jv9/gtv/gAkekdLKks6yAggHWdee05Q1QfZQ+9Iv
pUhViFQLV2HHIU8Iwmtg82MbpeX2CncKR+kNT0GaYSbAH3abOGGB1lov1qnE61kg
dYru1saKNJ3FGw0TcrC7kF77iR/ILd0HFJZt1EF5Yr63dl2ylPv6GlHHkDvS1mPa
eyFmYdMnZcjCWzEnBbzfoNaZnEfScWP0TD67KQIWTf/kH6Wl9pD03bLh1EDuADkl
CxiVJFvxtmQTZIHXkWgCnl7/BxpWuVxqlG1rPNvPw6A+b1GOyX2MoybxB9XodQdC
pzkIm3MN5G3GL/0z0sbSaryHyu2ZCUHRwsjW8RZBAgMBAAGjUDBOMB0GA1UdDgQW
BBSWOHzXXiF0aS7m4ZiAS+mrbpFfrzAfBgNVHSMEGDAWgBSWOHzXXiF0aS7m4ZiA
S+mrbpFfrzAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQAgLONi+87Y
ck6NOSeMlt9HjT2TH9AKfGQTgkKBfYdSfI66635uK8rSgNemNOvSVJwR15AHdUtH
HgynOp9w0flQHYPMRwBC0f23RISHpH/oB0iM5crHd0tqUZzKdwkWOZxkYGlIDkgl
hBbX29tTPwzQkjAHXk6YvCUXSTfey9PAZp50hCwEUdx1N7U7eXnWR4L5t3nsmDY0
iLaYa1OxJj490BZV3Avzbj+dwIuq1ryAb+bly+QOR/VoCBXqxnIofb9p+SLKI3Ll
B6gO0kh4k2z6mu+4vLtdNd0VrGLW8pXrcJXCSR5BwnR2+WB7fE/30pRsevFvhxJZ
Wvj82M2gHjYY
-----END CERTIFICATE-----" > "$PublicKey"
fi


if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <repo-url>"
    exit 1
else
    REPO_URL=$1
fi

if [[ $EUID -eq 0 ]]; then
   echo "WARNING: Initialising with root Priviledge" 1>&2
fi

(
mkdir ".gitcryptr"; cd ".gitcryptr"

#####
# Create clean_filter_openssl file AKA encryption.
cat << EOF > clean_filter_openssl
#!/bin/bash
openssl smime -encrypt -aes256 -binary -outform DEM "$PublicKey" 2> /dev/null  || cat
EOF

#####
# Create smudge_filter_openssl AKA decryption
cat << EOF > smudge_filter_openssl
#!/bin/bash"

# If decryption fails, use cat instead."
# Error messages are redirected to /dev/null."
openssl smime -decrypt -binary -inform DEM -inkey "$PrivateKey" 2> /dev/null || cat
EOF

#####
# Create diff_filter_openssl
cat << EOF > diff_filter_openssl
#!/bin/bash"

# If decryption fails, use cat instead."
# Error messages are redirected to /dev/null."
openssl smime -decrypt -binary -inform DEM -inkey "$PrivateKey" -in "\$1" 2> /dev/null || cat "\$1"
EOF
)
#####
# Link up to remote git
#####
chmod -R "+rx" .gitcryptr
echo "gitcryptr : If you're seeing this message from the git server something went wrong" > README.md
git init
git remote add origin $REPO_URL

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
echo -e "\n-- Excluding encryption configuration from git repository\n"
echo ".gitcryptr/*" > .git/info/exclude
echo "gitcryptr.sh" >> .git/info/exclude

ls -la .gitcryptr

#####
# Finish up and push README to master branch
#####
git add README.md
git commit -m "Initial gitcryptr commit"
git push -u origin master

clear
echo -e "\n\ngitcryptr is done. Clean your shell history\n"
