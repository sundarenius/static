#!/bin/bash

declare -a commands=(
  node_modules
  brew_packages
  os
)

case $1 in

  ${commands[1]})
    echo "/usr/local/lib/node_modules"
    echo
    ls /usr/local/lib/node_modules
    ;;

  ${commands[2]})
    echo "/usr/local/Cellar"
    echo
    ls /usr/local/Cellar
    ;;

  ${commands[3]})
    echo "CMD: sw_vers"
    echo
    sw_vers
    ;;

  *)
    echo Found no matching arguments, this is a bash script
    echo Available commands:
    echo
    printf '%s\n' "${commands[@]}"
    ;;
esac