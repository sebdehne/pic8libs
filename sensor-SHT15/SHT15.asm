	errorlevel  -302

#include "config.inc"

#ifndef SHT15_PWR
	error	"SHT15_PWR must be defined, for example: PORTA,0"
#endif
#ifndef SHT15_SCK
	error	"SHT15_SCK must be defined, for example: PORTA,0"
#endif
#ifndef SHT15_DATA
	error	"SHT15_DATA must be defined, for example: PORTA,0"
#endif
#ifndef CLOCKSPEED
	error	"CLOCKSPEED must be defined, for example: .8000000"
#endif



	udata_shr
d1							res 1
d2							res 1
d3							res 1
temp						res 1
loop_cnt					res 1
loop_cnt2					res 1
SHT15_databuffer			res 3
	global	SHT15_databuffer

	code

;
; Library for the SHT-15 sensor. 
;
; NOTE: It is recommended to run a watchdog timer 
;       which can reset the microcontroller for the situation
;       where it is waiting for input from the sensor but doesn`t 
;       get any. The library has currently no own timeout handling.
;
; All delay/timing code (_delay_* methods) are for 8Mhz and need to be adjusted
; when running at different speed


; call to setup the module
; sensor is powered off
SHT15_Init
	global	SHT15_Init
	banksel	TRISC
	bcf		TRISC, 0 ; PWR port
	bcf		TRISC, 1 ; CLK port
	call	data_read
	call	SHT15_power_off
	return

SHT15_power_on
	global	SHT15_power_on
	banksel	PORTC
	bsf		SHT15_PWR
	call	_delay_20ms; wait_for_startup
	return

SHT15_power_off
	global	SHT15_power_off
	call	sck_low
	banksel	PORTC
	bcf		SHT15_PWR
	return

SHT15_get_temp
	global SHT15_get_temp
	movlw	b'00000011' ; cmd for temperature
	movwf	temp
	call	SHT15_ReadRegister
	return

SHT15_get_humidity
	global	SHT15_get_humidity
	movlw	b'00000101' ; cmd for humidity
	movwf	temp
	call	SHT15_ReadRegister
	return

SHT15_BatteryCheck
	global	SHT15_BatteryCheck
	return

; =========================================
; below this line, all internal methods
; =========================================

; sends the command in temp and stores the response in SHT15_databuffer
; sets STATUS, Z to 1 if error
; sets STATUS, Z to 0 if success
SHT15_ReadRegister
	call	send_start
	movf	temp, W
	call	send_command
	btfsc	STATUS, Z
	goto	SHT15_ReadRegister_done ; abort here since cmd was not OK

	; wait for measurement done 	
	call	_delay_20ms
	call	_delay_20ms
	; wait for DATA line to be pulled low by sensor
SHT15_ReadRegister_wait
	call	_delay_5us
	call	data_read
	btfsc	STATUS, Z
	goto	SHT15_ReadRegister_wait ; data line not low yet, wait more
	
	; read data from sensor
	call	read_data

	; TODO: verify CRC

	bcf		STATUS, Z
SHT15_ReadRegister_done
	return

data_send_low
	banksel	TRISC
	bcf		TRISC, 2 ; output pin
	banksel	PORTC
	bcf		SHT15_DATA
	return
data_send_high
	banksel	TRISC
	bsf		TRISC, 2 ; input pin, pull-up will do the work
	return
data_read
	banksel	TRISC
	bsf		TRISC, 2 ; input pin
	banksel	PORTC
	bcf		STATUS, Z
	btfsc	SHT15_DATA
	bsf		STATUS, Z
	return
sck_high
	banksel	PORTC
	bsf		SHT15_SCK
	return
sck_low
	banksel	PORTC
	bcf		SHT15_SCK
	return


send_start
	call	_delay_5us
	call	sck_high
	call	_delay_5us
	call	_delay_5us
	call	data_send_low
	call	_delay_5us
	call	_delay_5us
	call	sck_low
	call	_delay_5us
	call	_delay_5us
	call	sck_high
	call	_delay_5us
	call	_delay_5us
	call	data_send_high
	call	_delay_5us
	call	_delay_5us
	call	sck_low
	call	_delay_5us
	call	_delay_5us
	call	data_send_low
	call	_delay_5us
	call	_delay_5us
	call	_delay_5us
	call	_delay_5us
	call	_delay_5us
	call	_delay_5us
	call	_delay_5us
	call	_delay_5us
	return

read_data
	movlw	.3 ; 2 data bytes + 1 crc byte
	movwf	loop_cnt
	movlw	SHT15_databuffer
	movwf	FSR
	bcf		STATUS, IRP
	btfsc	SHT15_databuffer, 0
	bsf		STATUS, IRP
read_data_byte
	movlw	.8
	movwf	loop_cnt2
read_data_byte_bit
	rlf		INDF, F
	; wait A
	call	_delay_5us
	; raise clock
	call	sck_high
	; wait B
	call	_delay_5us
	; read DATA
	call	data_read
	bsf		INDF, 0
	btfss	STATUS, Z
	bcf		INDF, 0

	; wait C	
	call	_delay_5us
	; clear clock
	call	sck_low
	; wait D
	call	_delay_5us
	; more bits to read?
	decfsz	loop_cnt2, F
	goto	read_data_byte_bit
	; send ACK
	call	data_send_low
	; wait A
	call	_delay_5us
	; raise clock
	call	sck_high
	; wait B
	call	_delay_5us
	; wait C
	call	_delay_5us
	; clear clock
	call	sck_low
	; wait D
	call	_delay_5us
	call	data_read ; release data line
	; more bytes to read?
	incf	FSR, F
	decfsz	loop_cnt, F
	goto	read_data_byte

read_data_done
	return

; sends command in W, and sets 
; STATUS, Z to 1 for NACK
; STATUS, Z to 0 for ACK
send_command
	; store value in W into temp
	movwf	temp
	; prepare the loop
	movlw	.8
	movwf	loop_cnt
	; send the bits now
send_command_loop
	; read the next bit
	rlf		temp, F

	; configure DATA line now
	btfss	STATUS, C
	goto	send_command_loop_low
	goto	send_command_loop_high

send_command_loop_high
	call	data_send_high
	goto	send_command_loop_cnt
send_command_loop_low
	call	data_send_low
	goto	send_command_loop_cnt
send_command_loop_cnt

	; wait A
	call	_delay_5us
	; rais clock
	call	sck_high
	; wait B
	call	_delay_5us
	; wait C
	call	_delay_5us
	; clear clock
	call	sck_low
	; wait D
	call	_delay_5us
	; loop for more bits
	decfsz	loop_cnt, F
	goto	send_command_loop

	; read ACK/NACK
	; wait A for slave to set DATA line
	call	_delay_5us
	; rais clock
	call	sck_high
	; wait B
	call	_delay_5us
	; read DATA (ACK/NACK) now and store bit in temp0
	call	data_read
	bsf		temp, 0
	btfss	STATUS, Z
	bcf		temp, 0
	; wait C
	call	_delay_5us
	; clear clock
	call	sck_low
	; wait D
	call	_delay_5us

	; move temp0 to Z
	bsf		STATUS, Z
	btfss	temp, 0
	bcf		STATUS, Z

	return


_delay_5us
			;6 cycles
	goto	$+1
	goto	$+1
	goto	$+1

			;4 cycles (including call)
	return

_delay_20ms
			;39993 cycles
	movlw	0x3E
	movwf	d1
	movlw	0x20
	movwf	d2
_delay_20ms_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	_delay_20ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return

	end