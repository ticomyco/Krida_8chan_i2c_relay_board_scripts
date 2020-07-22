#!/bin/bash
# Tested on Raspbian "buster" on a Raspberry Pi 4B

# This bash script can be used to enable/disable the individual relays on the
# Krida Electronics I2C 8-channel Solid State Relay Module 
# which uses the PCF8574 chip --
#  ( some modules may use PCF8574(A) chip). 

#Permission to use, copy, modify, and/or distribute this software for any purpose
#with or without fee is hereby granted.

#THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
#REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
#FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
#INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
#OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
#TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
#THIS SOFTWARE.

# Version V1 module: Use logical "0" for DISABLE, and "1" for ENABLE relay
#   NOTE: V1 module defaults to ALL RELAYS ENABLED when first powered on!
#         If this is undesirable, consider adding this script to your system 
#         boot scripts with the "init off" parameter, to minimize the time
#         that all relays are enabled when first powering on the system. 
#
# Version V2 module is opposite -- Use "1" for DISABLE and "0" for ENABLE,
#   (and all relays DISABLED when first powered on).
# This script is for V1 module.  For V2 module switch the "on" and "off" 
#  commands in this script. 
# 
# This script assumes that the 
# Requires package "i2c-tools" (apt-get install i2c-tools), a working i2c bus,
#  and assumes user running the script has write permissions to /dev/i2c-1 etc

# This script has very little error checking or sanity checks built-in, however
#  the use of a state file to keep track of which relays are currently enabled
#  and the use of a lock file to prevent this script from being run more than 
#  once simultaneously should make it safe to use with a system such as Mycodo
#  which theoretically could attempt to call this script with different commands#  simultaneously. 

ALLOFF="00"  # hex value for i2cset command to turn all relays off
ALLON="FF"   # hex value to turn all relays on

ADDR="0x27"  # i2c address of relay module (can be changed with dip switches
	     #  from 0x27 - 0x3F -- confirm the system sees the board using
	     #  'i2cdetect -y 1' if using bus 1)
BUS=1	     # i2c bus number -- list available buses with 'i2cdetect -l'

# State file: (relay status cannot be read from chip, so save state in a file)
# If controlling multiple relay boards, these file locations must be unique:
STATEFILE=/tmp/kridarelaystate.bin  # must be writable by this script
LOCKFILE=/tmp/kridarelay.lock

# Commands are: ./krida_8ch_relay_v1.sh init on   # turn all relays on
#               ./krida_8ch_relay_v1.sh init off  # turn all relays off

# Attempt to obtain a lock before continuing, wait up to 2 seconds
exec 100> $LOCKFILE || exit 1
flock -w 2 100 || exit 1
trap 'rm -f $LOCKFILE' EXIT

if (( $# != 2 )); then
	echo "Need two arguments! Proper usage: $0 (init|relay#) (on|off)"
	echo "Examples: "
	echo " $0 init on  # Init state file and set all relays on"
	echo " $0 3 off    # set relay#3 off"
	echo " $0 5 on     # set relay#5 on"
	exit 1
else
  case "$1" in
    "init") #initialize state file and set all relays off or on
	case "$2" in
  	   "on")
		# Need to write byte to i2c address and also to state file
		# 
		# save byte of relay state as integer into statefile:
		echo -n $((16#$ALLON)) > $STATEFILE
		# and write that byte to i2cset to trigger the relay:
		/usr/sbin/i2cset -y $BUS $ADDR 0x$ALLON
		;;
          "off")
		# save byte of relay state as hex integer into statefile:
		echo -n $((16#$ALLOFF)) > $STATEFILE
		# and write that byte to i2cset to trigger the relay:
		/usr/sbin/i2cset -y $BUS $ADDR 0x$ALLOFF
		;;
       	  *) 
		echo "invalid parameter! must be on or off"
		exit 1
	       	;;
	esac # end "init" case
	;;
    1|2|3|4|5|6|7|8) # enable/disable individual relays
	if [ -e $STATEFILE ] #  Minimal check that script has been run 
	then                 #  at least once before and a known state exists
	    # Read the state from the file as an integer: (decimal)
	    declare -i STATE=$(< $STATEFILE)
	     # Create a positive bit mask for the relay we wish to change
	     (( AMASK =  2 ** $(($1 - 1))  ))
     	     case $2 in 
		"on") 
		    # use an OR with a positive bit mask to enable only the
		    # bit for the desired relay and leave others unmodified
		    (( STATE |= $((AMASK)) ))
		    echo -n $((STATE)) > $STATEFILE # write new STATE to disk
		    printf -v HEXSTATESTR '%x' $STATE # need to make a text
		        # string of the new state in order to call i2cset:
		    /usr/sbin/i2cset -y $BUS $ADDR 0x$HEXSTATESTR
		    ;; # done enabling a relay
		"off")
		    (( BMASK = $((AMASK)) ))
		    (( BMASK ^= 255 )) # need to flip the bitmask first

		    # use an AND with a negative bit mask to disable only the
		    #  bit for the desired relay and leave others unmodified
		    (( STATE &= $((BMASK)) ))
		    echo -n $((STATE)) > $STATEFILE
		    printf -v HEXSTATESTR '%x' $STATE # need to make a text
		        # string of the new state in order to call i2cset:
		    /usr/sbin/i2cset -y $BUS $ADDR 0x$HEXSTATESTR
		    ;;
		*)
		    echo "error! only on or off allowed! run $0 to see examples"
		    exit 1
		esac # end case for individual relays	
	else # statefile didn't exist
	    echo "Error! must run script first with init on or off to establish the statefile."
	    exit 1
	fi 
	;;
     *) # shouldn't end up here
	echo "error! First parameter must be either init or a relay number 1-8"
	exit 1
     esac # end case for first level parameters
fi # end check if script was called with 2 parameters
