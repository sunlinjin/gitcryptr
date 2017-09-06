# gitcryptr

#### Automatically encrypt and decrypt commits to git repository

Hooks git encryption filters to target folder and inits the repository

## Usage
```
cd secretproject
curl "https://raw.githubusercontent.com/kh4st3x/gitcryptr/master/gitcryptr.sh" > gitcryptr.sh
chmod +x gitcryptr.sh
./gitcryptr.sh <password> <git-repo-link>
```

## Features

* Transparent encryption when adding
* Transparent decryption when pulling or diff
* AES-256-ECB encryption
  * AES-256-CBC can be chosen, but it recreates file at each decription, loosing file tracking
* Excludes encryption configuration files from being pushed
* Run once and forget

## Demo
[![asciicast](https://asciinema.org/a/136544.png)](https://asciinema.org/a/136544)


[GIF demo version](http://i.imgur.com/bKiURmw.gif)
