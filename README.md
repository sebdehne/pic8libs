pic8libs
========

Libraries for 8-bit PIC microcontroller written in assembly. 

Most libraries are developed against the PIC16F690, although they should
work with most 8-bit pics. A main.asm and config.ini file is included to demo 
the given library.

For more documentation, see the library source code files.



sensor-SHT15
------------
Library which talks to the SHT15 temperature sensor. The lib offers:
- power up/down of sensor
- read temperature and humidity (using factory resolution)
- low voltage warning (useful when powered by battery)



