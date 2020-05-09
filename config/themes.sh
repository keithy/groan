#!/bin/bash
# http://www.karimsultan.com/live/?p=10136
 
case $THEME in
    none | off | 0)
    :
    ;;
    neon)
        bold=$'\e[33m' 
        dim=$'\e[34m'  
        italic=$'\e[32m' 
        underline=$'\e[31m'  
        reset=$'\e[0m' 
    ;;
    *)
        bold=$'\e[1m' 
        dim=$'\e[2m'  
        italic=$'\e[3m' 
        underline=$'\e[4m'  
        reset=$'\e[0m' 
    ;;
esac


