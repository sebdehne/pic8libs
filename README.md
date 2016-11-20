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

sensor-ChipCap2
---------------
Library which talks to the ChipCap2 sensor over I2C. This lib offers:
- power up/down of the sensor
- read temperature and humidity

RfReceiverLibrary
-----------------
Library to receive and decode a message from a 433Mhz rf module. The analog signal (RSSI) is filtered through a comparator and then decoded using [manchester code](https://en.wikipedia.org/wiki/Manchester_code).

rf-tx-AM-RT4-433
----------------
Library to encode and transmit a message to a 433Mhz rf module. The message is encoded using [manchester code](https://en.wikipedia.org/wiki/Manchester_code).


