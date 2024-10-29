#!/usr/bin/env bash
# vim: ts=2 sts=0 sw=0 et list
set -e

if [ ! -f ./avatar.json ]
then
  echo "Not an avatar!"
  exit
fi

libpath="libs"
: "${assetdir:=$(dirname "$(realpath "$0")")}"
confdir="$HOME/.config/figmanager"

ACTION="$1"
shift

[ -f "$confdir/config.properties" ] &&. "$confdir/config.properties"
[ -f "$assetdir/config.properties" ] &&. "$assetdir/config.properties"

read-asset() {
  if [ -f "$confdir/$1" ]
  then
    cat "$confdir/$1"
  fi
  if [ -f "$confdir/super/$1" ]
  then
    cat "$confdir/super/$1"
  elif [ -f "$assetdir/$1" ]
  then
    cat "$assetdir/$1"
  fi
}

if [[ "$ACTION" == "list" ]]; then
  read-asset repos.properties |
  while read -r repo
  do
    REPONAME="$(echo "$repo" | cut -d "=" -f 1)"
    REPOURL="$(echo "$repo" | cut -d "=" -f 2)"
    echo "REPO $REPONAME"
    while read -r library
    do
      LIBNAME="$(echo "$library" | cut -d "=" -f 1)"
      echo "LIBRARY $LIBNAME"
    done <<< "$(curl -s "$REPOURL")"
  done
fi

if [[ "$ACTION" == "get" ]]; then
  read-asset repos.properties |
  while read -r repo
  do
    REPONAME="$(echo "$repo" | cut -d "=" -f 1)"
    REPOURL="$(echo "$repo" | cut -d "=" -f 2)"
    echo "Checking Repo $REPONAME"
    while read -r library
    do
      LIBNAME="$(echo "$library" | cut -d "=" -f 1)"
      LIBURL="$(echo "$library" | cut -d "=" -f 2)"
      echo "Library $LIBNAME"
      echo "URL $LIBURL"

      for arg
      do
        if [[ "$arg" == "$LIBNAME" ]]; then
          echo "Found! Downloading now."
          mkdir -p "$libpath/$REPONAME"
          curl "$LIBURL" > "$libpath/$REPONAME/$LIBNAME.lua"
          echo "Downloaded to '$libpath/$REPONAME/$LIBNAME.lua'"
          exit
        fi
      done
    done < "$HOME/.cache/figmanager/$REPONAME"
  done
fi

if [[ "$ACTION" == "update" ]]; then
  read-asset repos.properties |
  while read -r repo
  do 
    REPONAME="$(echo "$repo" | cut -d "=" -f 1)"
    REPOURL="$(echo "$repo" | cut -d "=" -f 2)"
    echo "REPO $REPONAME"
    echo "URL $REPOURL"
    curl "$REPOURL" > "$HOME/.cache/figmanager/$REPONAME"
  done
fi

if [[ "$ACTION" == "upgrade" ]]; then
  while read -r file
  do
    "$0" get "$(basename $file .lua)"
  done <<< "$(find "$libpath" -type f)"
fi

