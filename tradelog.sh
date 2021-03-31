#!/bin/bash

## VARIABLES ##
# Some variables exports for correct script working
export POSIXLY_CORRECT=yes
export LC_NUMERIC=en_US.UTF-8

# Some variables for storing arguments
TICKERS=""
LOG_FILE=""
STDINPUT=""

TICK=0
PROF=0
POS=0
LAST=0

## FUNCTIONS ##
# Function of printing help message for user
function print_help() {
  echo "Usage: tradelog [-h|--help] [FILTER] [COMMAND] [LOG FILES]"
  echo "Shows stocks information(analyzing, statistics, filtering) by user requirements"
  echo ""
  echo "FILTERS"
  echo "  -a DATETIME       process records AFTER given date(without it)"
  echo "                    DATETIME is given in the format YYYY-MM-DD HH:MM:SS"
  echo "  -b DATETIME       process records BEFORE given date(without it)"
  echo "                    DATETIME is given in the format YYYY-MM-DD HH:MM:SS"
  echo "  -t TICKER         process records with given TICKER"
  echo "                    if the filter acquires multiple times, will be processed"
  echo "                    all records with these TICKERS"
  echo "  -w WIDTH" #TODO
  echo "  -h --help         display this help and exit"
  echo ""
  echo "COMMANDS"
  echo "  list_tick         print records by given TICKERS"
  echo "  profit            print total gain"
  echo "  pos               print list of obtained stocks in descending order by value "
  echo "  last-price        print last price for each ticket"
  echo "  hist-ord          print a histogram of transaction number for each ticket"
  echo "  graph-pos         print a graph of obtained stocks values for each ticket"
  exit
}

# Function of printing by tickers, which are given by user
function print_by_tickers() {
  ARRAY_OF_TICKETS=($TICKERS)
  awk -v t="${ARRAY_OF_TICKETS[*]}" -F';' '
  BEGIN { n=split(t,list," ");
  for (i=1;i<=n;i++)
  tickers[list[i]] }
  $2 in tickers {print}' $1
}

# Function of printing the list of tickets
function list_tick() {
  awk -F';' '{print $2}' $1 | sort -u
}

# Function, that prints profit of deals
function profit() {
  awk -F';' 'BEGIN {profit = 0}
  {if ($3 == "buy")
      profit = profit - ($4 * $6)
   else
      profit = profit + ($4 * $6)}
  END {printf("%.2f\n", profit)}' $1
}

function pos() {
  arr=($(list_tick "-"))
  for tick in ${arr[*]}; do
    awk -v key=$tick -F';' '
    BEGIN {num = 0}
    {if ($2 == key && $3 == "buy")
        num = num + $6
    if ($2 == key && $3 == "sell")
        num = num - $6
    if ($2 == key)
        last = $4}
    END {printf("%-10s:%12.2f\n", key, last*num)}' $1
  done
}

# Function, that prints last price of a stock of each ticket
function last_price() {
  arr=($(list_tick "-"))
  for tick in ${arr[*]}; do
    awk -v key=$tick -F';' '
    BEGIN {last=0}
    {if ($2 == key)
        last = $4}
    END {printf("%-10s:%8.2f\n", key, last)}' $1
  done
}

## START OF THE PROGRAM
# OPTIONS PROCESSING
while getopts :ha:b:t:w: o; do
  case "$o" in
  h)
    print_help
    ;;
  a) AFTER_DATE="$OPTARG"
    ;;
  b) BEFORE_DETE="$OPTARG"
    ;;
  t)
    TICKERS="$TICKERS $OPTARG"
    ;;
  w) #TODO
    ;;
  *)
    #TODO
    ;;
  esac
done

# ARGUMENTS PROCESSING
((OPTIND--))
shift $OPTIND
for i in $*; do
  if [ $1 == "list-tick" ]; then
    TICK=1
  elif [ $1 == "profit" ]; then
    PROF=1
  elif [ $1 == "pos" ]; then
    POS=1
  elif [ $1 == "last-price" ]; then
    LAST=1
  elif [ $1 == "--help" ]; then
      print_help
  else
    LOG_FILE=$1
#    if [[ "$LOG_FILE" == *".gz"* ]]; then
#      gzip -dk "$LOG_FILE" #TODO delete 'k'
#    fi
  fi
  shift
done

# COMMAND PROCESSING
if [[ "$TICKERS" != "" ]]; then
  if [[ $TICK -eq 1 ]]; then
    print_by_tickers $LOG_FILE | list_tick $STDINPUT
  elif [[ $PROF -eq 1 ]]; then
    print_by_tickers $LOG_FILE | profit $STDINPUT
  elif [ $LAST -eq 1 ]; then
    print_by_tickers $LOG_FILE | last_price $LOG_FILE
  elif [ $POS -eq 1 ]; then
    print_by_tickers $LOG_FILE | pos $LOG_FILE | sort -k2nr -t:
  else
    if [[ "$LOG_FILE" == *".gz"* ]]; then
      gzip -dc "$LOG_FILE" | print_by_tickers #TODO remade .gz processing
    fi
  fi
else
  if [[ $TICK -eq 1 ]]; then
    list_tick $LOG_FILE
  elif [[ $PROF -eq 1 ]]; then
    profit $LOG_FILE
  elif [ $LAST -eq 1 ]; then
    cat $LOG_FILE | last_price $LOG_FILE
    elif [ $POS -eq 1 ]; then
    cat $LOG_FILE | pos $LOG_FILE | sort -k2nr -t:
  else
    while read A; do
      echo $A
    done
  fi
fi

## END OF THE PROGRAM
