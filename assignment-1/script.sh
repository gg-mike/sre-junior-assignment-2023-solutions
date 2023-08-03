#!/bin/bash

# Global variables used for setting up options
is_method=false
is_user_agent=false
user_agent=""

# Function for displaying usage message
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help           Display this help message"
 echo " -m, --method         Restrict parsing of logs only to provided user agent"
 echo " -u, --user_agent     Print output number of request per method/address instead of just per address"
}

set_user_agent() {
  is_user_agent=true
  user_agent=$1
  if [ "$user_agent" = "" ]
  then
    echo "User agent not provided" >&2
    exit 1
  fi
}

# Function for parsing command line arguments and setting up options
handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in
      -h | --help)           usage; exit 0;;
      -m | --method)         is_method=true;;
      -u | --user_agent)     set_user_agent $2; shift;;
      *)                     echo "Invalid option: $1" >&2; usage; exit 1;;
    esac
    shift
  done
}

# Function for cleaning up work env
cleanup() {
  echo "Cleaning up"
  rm -rf "logs/"
}

# Function for extracting logs from archive
extract_file() {
  echo Extracting logs
  tar -xf logs.tar.bz2
}

# Function for analyzing logs based on set options
analyze_file() {
  echo Analyzing logs
  if [ "$is_user_agent" = true ] 
  then
    echo "Filtering results for: '$user_agent'"
  fi

  if [ "$is_method" = true ] 
  then
    echo "ADDRESS              METHODS REQUESTS"
    sed 's/"//g' logs/logs.log | 
    awk -v filter="$user_agent" '
      { if (match($0, "user_agent: " filter)) { REQUESTS[$14, $6]+=1 } } 
      END { 
        for (ADDRESS_METHOD in REQUESTS) {
          split(ADDRESS_METHOD,SEP,SUBSEP); 
          printf "%-20s %-7s %s\n", SEP[1], SEP[2], REQUESTS[ADDRESS_METHOD] 
        }
      }' |
    sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n
  else
    echo "ADDRESS              REQUESTS"
    sed 's/"//g' logs/logs.log | 
    awk -v filter="$user_agent" '
      { if (match($0, "user_agent: " filter)) { REQUESTS[$14]+=1 } } 
      END { 
        for (ADDRESS in REQUESTS) 
          printf "%-20s %s\n", ADDRESS, REQUESTS[ADDRESS] 
      }' |
    sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n
  fi
}

handle_options "$@"
extract_file

# In the event of the crash this command will ensure the extracted files are deleted
trap '
  EXITCODE=$?;
  echo "$BASH_COMMAND at line $LINENO exited with code $EXITCODE";
  cleanup;
  exit $EXITCODE' ERR

analyze_file
cleanup

exit 0
