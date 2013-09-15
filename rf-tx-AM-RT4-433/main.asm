	errorlevel  -302


	#include "config.inc" 
	
	__CONFIG       _CP_OFF & _CPD_OFF & _WDT_OFF & _BOR_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT  & _MCLRE_OFF & _FCMEN_OFF & _IESO_OFF
	
	
	udata
d1				res	1
d2				res 1
d3				res	1
Values			res	2


	; imported from the rf_protocol_tx module
	extern	MsgAddr
	extern	MsgLen
	extern	RF_TX_Init
	extern	RF_TX_PowerOn
	extern	RF_TX_PowerOff
	extern	RF_TX_SendMsg
	


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
	
	; Configure the watch-dog timer, but disable it for now
	banksel	OPTION_REG
	movlw	b'00001110' ; 110 == 64 pre-scaler & WDT selected
		;	  ||||||||---- PS0 - Timer 0:  
		;	  |||||||----- PS1
		;	  ||||||------ PS2
		;	  |||||------- PSA -  Assign prescaler to Timer0
		;	  ||||-------- TOSE - LtoH edge
		;	  |||--------- TOCS - Timer0 uses IntClk
		;	  ||---------- INTEDG - falling edge RB0
		;	  |----------- NOT_RABPU - pull-ups enabled
	movwf	OPTION_REG
	banksel	WDTCON
	movlw	b'00001100' ; 0110 ==  2048 (~  4 seconds)
	movlw	b'00010010' ; 1001 == 16384 (~ 32 seconds)
	;            |||||
	;            ||||+--- disable watchdog timer SWDTEN
	;            |||+---- pre-scaler WDTPS0
	;            ||+----- pre-scaler WDTPS1
	;            |+------ pre-scaler WDTPS2
	;            +------- pre-scaler WDTPS3
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
	clrf 	ANSEL
	clrf 	ANSELH

	; Configure PortA, all output
	BANKSEL TRISA
	clrf	TRISA
	
	; Configure PortB
	BANKSEL	TRISB
	clrf	TRISB
	
	; Set entire portC as output
	BANKSEL TRISC
	clrf	TRISC

	; set all output ports to LOW
	banksel	PORTA
	clrf	PORTA
	clrf	PORTB
	clrf	PORTC

	; init the rf_protocol_tx.asm module
	call	RF_TX_Init

	; init done

_main
	call	_delay_1000ms
	call	_delay_1000ms
	call	_delay_1000ms
	call	_delay_1000ms
	call	_delay_1000ms
	call	_delay_1000ms
	call	_delay_1000ms
	call	_delay_1000ms
	call	_delay_1000ms
	call	_delay_1000ms

	; load demo data into buffer (1337)
	movlw	b'00000101'
	movwf	Values
	movlw	b'00111001'
	movwf	Values+1

	; send demo data over RF now
	; enable RF module
	call	RF_TX_PowerOn
	; Load the value's location and send the msg
	movlw	HIGH	Values
	movwf	MsgAddr
	movlw	LOW		Values
	movwf	MsgAddr+1
	movlw	.2
	movwf	MsgLen
	; and transmit the data now
	call	RF_TX_SendMsg
	; power down RF module
	call	RF_TX_PowerOff

	clrwdt	; done, reset watchdog
	goto	_main


_delay_1ms
			;1993 cycles
	movlw	0x8E
	movwf	d1
	movlw	0x02
	movwf	d2
_delay_1ms_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	_delay_1ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
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
	
	end