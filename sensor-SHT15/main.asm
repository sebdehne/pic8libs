	errorlevel  -302


	#include "config.inc" 
	
	__CONFIG       _CP_OFF & _CPD_OFF & _WDT_OFF & _BOR_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT  & _MCLRE_OFF & _FCMEN_OFF & _IESO_OFF
	
	
	udata
d1				res	1
d2				res 1
d3				res	1


	; imported from the sht15 module
	extern	SHT15_Init			; method
	extern	SHT15_get_temp		; method
	


Reset		CODE	0x0
	pagesel	_init
	goto	_init
	code
	
_init
	; set the requested clockspeed
	banksel	OSCCON
	if CLOCKSPEED == .8000000
		movlw	b'01110000'
	else
		if CLOCKSPEED == .4000000
			movlw	b'01100000'
		else
			error	"Unsupported clockspeed"
		endif
	endif
	movwf	OSCCON
	
	; setup option register
	; timer pre-scaler set to 64
	banksel	OPTION_REG
	movlw	b'00001100'	
		;	  ||||||||---- PS0 - Timer 0:  
		;	  |||||||----- PS1
		;	  ||||||------ PS2
		;	  |||||------- PSA -  Assign prescaler to Timer0
		;	  ||||-------- TOSE - LtoH edge
		;	  |||--------- TOCS - Timer0 uses IntClk
		;	  ||---------- INTEDG - falling edge RB0
		;	  |----------- NOT_RABPU - pull-ups enabled
	movwf	OPTION_REG
	; configure the watch-dog timer now
	CLRWDT
	movlw	b'00010011' ; 65536 + enable
	banksel	WDTCON
	movwf	WDTCON
	
	; set the OSCTUNE value now
	banksel	OSCTUNE
	movlw	OSCTUNE_VALUE
	movwf	OSCTUNE

	; Select the clock for our A/D conversations
	BANKSEL	ADCON1
	MOVLW 	B'01010000'	; ADC Fosc/16
	MOVWF 	ADCON1

	; all ports to digital
	banksel	ANSEL
	clrf	ANSEL
	clrf	ANSELH

	; Configure PortA as output
	BANKSEL TRISA
	CLRF	TRISA			; output all
	
	; Set entire portB as output
	BANKSEL	TRISB
	clrf	TRISB
	
	; Set entire portC as output
	BANKSEL TRISC
	CLRF	TRISC			; output all

	; set all output ports to LOW
	banksel	PORTA
	clrf	PORTA
	clrf	PORTB
	clrf	PORTC

	; init the rf_protocol_tx.asm module
	call	SHT15_Init

	call	blink_short
	call	blink_short
	call	blink_short
	call	blink_short
	call	blink_short
	call	blink_short
	call	_delay_1000ms

	; init done
	goto	_main

_main
	call	blink
	call	SHT15_get_temp
	CLRWDT

	goto	_main

blink
	bsf	PORTB, 6
	call	_delay_1000ms
	bcf	PORTB, 6
	call	_delay_1000ms
	return

blink_short
	bsf	PORTB, 6
	call	_delay_20ms
	call	_delay_20ms
	call	_delay_20ms
	call	_delay_20ms
	call	_delay_20ms
	bcf	PORTB, 6
	call	_delay_20ms
	call	_delay_20ms
	call	_delay_20ms
	call	_delay_20ms
	call	_delay_20ms
	return


_delay_1000ms
			;3999994 cycles
	movlw	0x23
	movwf	d1
	movlw	0xB9
	movwf	d2
	movlw	0x09
	movwf	d3
_delay_1000ms_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	$+2
	decfsz	d3, f
	goto	_delay_1000ms_0

			;2 cycles
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