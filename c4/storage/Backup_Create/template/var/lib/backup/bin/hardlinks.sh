#!/bin/bash

# Program name: hardlinks

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

##########################################################################
# Title      :  hardlinks - list hardlinks or rebuild from list
# Author     :  Simon Blandford <simon -at- onepointltd -dt- com>
# Date       :  2008-07-31
# Requires   :  awk
# Category   :  Administration
# Version    :  1.0.0
# Copyright  :  Simon Blandford, Onepoint Consulting Limited
# License    :  GPLv3 (see above)
##########################################################################
# Description
# Store hardlink information in a file which can then be used to
# remove hardlinks or restore the hardlinks.
# This is intended to be used with backup and archiving systems that do
# not support hardlinks. Simply store the hardlink information as part of
# the archive so that the hardlinks can be regenerated when the archive is
# unpacked.
# the -s option is used to suppress the progress count when purging or
# restoring links.
# the -p option supresses errors when a file in the list isn't found
##########################################################################



function usage()
{
    echo "Usage: `basename $0` scan rootdir linklistfile"
    echo "       `basename $0` [-sp] purge rootdir linklistfile"
    echo "       `basename $0` [-sp] restore rootdir linklistfile"
    echo "Options: -s no counter display"
    echo "         -p no error on file in list not found"
    exit 0
}

function act_on_list()
{
  if [ ! -f "$linkListFile" ]; then
    echo "Error: Unable to open input link list file: $linkListFile." >&2
    exit 1
  fi
  totFiles=`wc -l $linkListFile | awk '{ print $1 }'`
  while read -r currentEntry; do
    inum=$( echo $currentEntry | awk '{ print $1 }' )
    #Change file space escapes (\ ) to *, extract the filename by deleting up to last space
    #then change the * back to spaces.
    fileName=$( echo "$currentEntry" | awk '{ for (i=2; i<=NF; i++) printf (" %s",$i) }' )
    #Remove leading space and . and prepend path
    fileName="$rootDir""${fileName:2}"
    if [ ! -f "$fileName" ]; then
      if [ "$suppressNoFileErr" != "yes" ]; then
        echo "Error: File $fileName can not be found in $currentEntry." >&2
        exitCode=1
        continue
      fi
    fi
    fileSize=`ls -l "$fileName" | awk '{ print $5 }'`
    sizeUnLinkedTotal=$(( $sizeUnLinkedTotal + $fileSize ))
    if [ "$inum" != "$lastInum" ]; then
      sizeLinkedTotal=$(( $sizeLinkedTotal + $fileSize ))
      baseFile="$fileName"
    else
      rm -f "$fileName"
      if [ $1 == "restore" ]; then
        ln "$baseFile" "$fileName"
      fi
    fi
    lastInum=$inum
    if [ $(( counter++ % 100 )) -eq 99 ] && [ "$noiseLevel" != "silent" ]; then
      echo "Processed $counter files of $totFiles"
    fi
  done < "$linkListFile"
  if [ "$noiseLevel" != "silent" ]; then
    echo "Processed $counter files of $totFiles"
  fi
}

while getopts hps c
do
  case $c in
    h)
      usage
      ;;
    s)
      noiseLevel="silent"
      ;;
    p)
      suppressNoFileErr="yes"
      ;;
    ?)
      usage
      ;;
  esac
done
shift $(($OPTIND - 1))

if [ $# -ne 3 ]; then usage; fi

rootDir="$2"
linkListFile="$3"

if [ ! -d "$rootDir" ]; then
  echo "Error: Can't find root directory: $rootDir." >&2
  exit 1
fi

exitCode=0
case $1 in
  scan)
    echo 'cd '"$rootDir"'; find . -type f -links +1 -printf "%i %h/%f\n" | sort' | bash > "$linkListFile"
    ;;
  purge)
    act_on_list "purge"
    ;;
  restore)
    act_on_list "restore"
    ;;
  *)
    usage
    ;;
esac

exit $exitCode
