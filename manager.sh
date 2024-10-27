#!/usr/bin/env bash

if [ ! -f ./avatar.json ]
then
  echo "Not an avatar!"
  exit
fi

DIRECTORY="$(dirname "$(realpath $0)")"

ACTION="$1"
ARGUMENT="$2"

if [[ "$ACTION" == "get" ]]; then
  while read -r repo
  do
    REPONAME="$(echo "$repo" | cut -d "=" -f 1)"
    REPOURL="$(echo "$repo" | cut -d "=" -f 2)"
    echo "Checking Repo $REPONAME"
    echo "URL $REPOURL"
    while read -r library
    do
      LIBNAME="$(echo "$library" | cut -d "=" -f 1)"
      LIBURL="$(echo "$library" | cut -d "=" -f 2)"
      echo "Library $LIBNAME"
      echo "URL $LIBURL"

      if [[ "$ARGUMENT" == "$LIBNAME" ]]; then
        echo "Found! Downloading now."
        mkdir -p "libs/$REPONAME"
        curl "$LIBURL" > "libs/$REPONAME/$LIBNAME.lua"
        echo "Downloaded to 'libs/$REPONAME/$LIBNAME.lua'"
        exit
      fi
    done <<< "$(curl "$REPOURL")"
  done < "$DIRECTORY/repos"
fi

