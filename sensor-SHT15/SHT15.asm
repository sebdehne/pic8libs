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



	udata
d1							res 1
d2							res 1
d3							res 1
temp						res 1
loop_cnt					res 1
loop_cnt2					res 1
data_buffer					res 3


	code

SHT15_Init
	global	SHT15_Init

	banksel	TRISC
	bcf		TRISC, 0
	bcf		TRISC, 1
	bcf		TRISC, 2

	call	SHT15_power_off

	return

SHT15_power_on
	global	SHT15_power_on
	bsf		SHT15_PWR
	call	set_idle
	call	_delay_20ms; wait_for_startup
	return
SHT15_power_off
	global	SHT15_power_off
	bcf		SHT15_PWR
	bcf		SHT15_SCK
	bcf		SHT15_DATA
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

; sends the command in temp and stores the response in data_buffer
; sets STATUS, Z to 1 if error
; sets STATUS, Z to 0 if success
SHT15_ReadRegister
	call	send_start
	movf	temp, W
	call	send_command
	btfsc	STATUS, Z
	goto	SHT15_ReadRegister_done ; abort here since cmd was not OK

	; wait for measurement done 	
	call	configure_for_read
	call	_delay_20ms
	call	_delay_20ms
	; wait for DATA line to be pulled low by sensor
SHT15_ReadRegister_wait
	call	_delay_5us
	btfsc	SHT15_DATA
	goto	SHT15_ReadRegister_wait ; data line not low yet, wait more
	
	; read data from sensor
	call	read_data
	call	set_idle

	; TODO: verify CRC

	bcf		STATUS, Z
SHT15_ReadRegister_done
	return

send_start
	call  	configure_for_write
	banksel	PORTC
	call	_delay_5us
	bsf		SHT15_SCK
	call	_delay_5us
	call	_delay_5us
	bcf		SHT15_DATA
	call	_delay_5us
	call	_delay_5us
	bcf		SHT15_SCK
	call	_delay_5us
	call	_delay_5us
	bsf		SHT15_SCK
	call	_delay_5us
	call	_delay_5us
	bsf		SHT15_DATA
	call	_delay_5us
	call	_delay_5us
	bcf		SHT15_SCK
	call	_delay_5us
	call	_delay_5us
	bcf		SHT15_DATA
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
	movlw	data_buffer
	movwf	FSR
	bcf		STATUS, IRP
	btfsc	data_buffer, 0
	bsf		STATUS, IRP
read_data_byte
	movlw	.8
	movwf	loop_cnt2
read_data_byte_bit
	rlf		INDF, F
	; wait A
	call	_delay_5us
	; raise clock
	bsf		SHT15_SCK
	; wait B
	call	_delay_5us
	; read DATA
	bsf		INDF, 0
	btfss	SHT15_DATA
	bcf		INDF, 0
	; wait C	
	call	_delay_5us
	; clear clock
	bcf		SHT15_SCK
	; wait D
	call	_delay_5us
	; more bits to read?
	decfsz	loop_cnt2, F
	goto	read_data_byte_bit
	; send ACK
	call	configure_for_write
	bcf		SHT15_DATA
	; wait A
	call	_delay_5us
	; raise clock
	bsf		SHT15_SCK
	; wait B
	call	_delay_5us
	; wait C
	call	_delay_5us
	; clear clock
	bcf		SHT15_SCK
	; wait D
	call	_delay_5us
	call	configure_for_read
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
	bsf		SHT15_DATA
	btfss	STATUS, C
	bcf		SHT15_DATA
	; wait A
	call	_delay_5us
	; rais clock
	bsf		SHT15_SCK
	; wait B
	call	_delay_5us
	; wait C
	call	_delay_5us
	; clear clock
	bcf		SHT15_SCK
	; wait D
	call	_delay_5us
	; loop for more bits
	decfsz	loop_cnt, F
	goto	send_command_loop

	; read ACK/NACK
	call	configure_for_read
	; wait A for slave to set DATA line
	call	_delay_5us
	; rais clock
	bsf		SHT15_SCK
	; wait B
	call	_delay_5us
	; read DATA (ACK/NACK) now and store bit in temp0
	bsf		temp, 0
	btfss	SHT15_DATA
	bcf		temp, 0
	; wait C
	call	_delay_5us
	; clear clock
	bcf		SHT15_SCK
	; wait D
	call	_delay_5us

	; move temp0 to Z
	bsf		STATUS, Z
	btfss	temp, 0
	bcf		STATUS, Z

	return

configure_for_write
	banksel	TRISC
	bcf		TRISC, 2
	banksel	PORTC
	return

configure_for_read
	banksel	TRISC
	bsf		TRISC, 2
	banksel	PORTC
	return

set_idle
	; set to idle state
	call	configure_for_write
	banksel	PORTC
	bcf		SHT15_SCK
	bsf		SHT15_DATA
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