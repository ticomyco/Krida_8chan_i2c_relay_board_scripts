# Krida_8chan_i2c_relay_board_scripts
Bash shell scripts to manipulate the Krida 8channel solid state relay boards using the PCF8574 chip

 This bash script can be used to enable/disable the individual relays on the
 Krida Electronics I2C 8-channel Solid State Relay Module 
 which uses the PCF8574 chip --
  ( some modules may use PCF8574(A) chip). 

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.

 Version V1 module: Use logical "0" for DISABLE, and "1" for ENABLE relay
   NOTE: V1 module defaults to ALL RELAYS ENABLED when first powered on!
         If this is undesirable, consider adding this script to your system 
         boot scripts with the "init off" parameter, to minimize the time
         that all relays are enabled when first powering on the system. 

 Version V2 module is opposite -- Use "1" for DISABLE and "0" for ENABLE,
   (and all relays DISABLED when first powered on).
 This script is for V1 module.  For V2 module switch the "on" and "off" 
  commands in this script. 
 
 This script assumes that the 
 Requires package "i2c-tools" (apt-get install i2c-tools), a working i2c bus,
  and assumes user running the script has write permissions to /dev/i2c-1 etc

 This script has very little error checking or sanity checks built-in, however
  the use of a state file to keep track of which relays are currently enabled
  and the use of a lock file to prevent this script from being run more than 
  once simultaneously should make it safe to use with a system such as Mycodo
  which theoretically could attempt to call this script with different commands
  simultaneously. 
