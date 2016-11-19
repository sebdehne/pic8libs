	errorlevel  -302


	#include "config.inc" 
	
	__CONFIG       _CP_OFF & _CPD_OFF & _WDT_OFF & _BOR_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT  & _MCLRE_OFF & _FCMEN_OFF & _IESO_OFF

mainData		udata 0x20 ; 9 bytes -> 0x2b
d1				res	1
d2				res 1
d3				res	1
temp			res 1

	; imported from the rf_protocol_tx module
	extern	RF_RX_Init			; method
	extern	RF_RX_ReceiveMsg	; method
	extern	RfRxMsgBuffer 		; variable
	extern	RfRxMsgLen		    ; variable
	extern	RfRxReceiveResult	; variable


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
	
	; set the OSCTUNE value now
	banksel	OSCTUNE
	movlw	OSCTUNE_VALUE
	movwf	OSCTUNE

	; Configure no watch-dog timer
	banksel	OPTION_REG
	movlw	b'00000000' ; 111 == 128 pre-scaler & WDT selected
		;	  ||||||||---- PS PreScale 
		;	  |||||||----- PS PreScale
		;	  ||||||------ PS PreScale
		;	  |||||------- PSA -  0=Assign prescaler to Timer0 / 1=Assign prescaler to WDT
		;	  ||||-------- TOSE - LtoH edge
		;	  |||--------- TOCS - Timer0 uses IntClk
		;	  ||---------- INTEDG - falling edge RB0
		;	  |----------- NOT_RABPU - pull-ups enabled
	movwf	OPTION_REG
	banksel	WDTCON
	movlw	b'00000000' ; 1011 == 65536 ((65536 * 128 (pre-scale))/32000Hz = ~ 4,37 min)
;	movlw	b'00001100' ; 0110 == 2048 ((65536 * 64 (pre-scale))/32000Hz = ~ 4 sec)
	;            |||||
	;            ||||+--- 0=disabled watchdog timer SWDTEN
	;            |||+---- pre-scaler WDTPS0
	;            ||+----- pre-scaler WDTPS1
	;            |+------ pre-scaler WDTPS2
	;            +------- pre-scaler WDTPS3
	movwf	WDTCON

	; Select the clock for our A/D conversations
	BANKSEL	ADCON1
	MOVLW 	B'01010000'	; ADC Fosc/16
	MOVWF 	ADCON1

	; all ports to digital
	banksel	ANSEL
	movlw	b'00000000'
	movwf	ANSEL
	movlw	b'00000000'
	movwf	ANSELH

	; Configure PortA
	BANKSEL TRISA
	movlw	b'00000000' ; all output
	movwf	TRISA
	
	; Configure PortB
	BANKSEL	TRISB
	movlw	b'00000000' ; all output
	movwf	TRISB
	
	; Set entire portC as output
	BANKSEL TRISC
	movlw	b'00000000'	; all output
	movwf	TRISC

	; set all output ports to LOW
	banksel	PORTA
	clrf	PORTA
	clrf	PORTB
	clrf	PORTC

	; init libraries
	call	RF_RX_Init

	call	BlinkLong


_main
	; 2 long blink => Success
	; 1 long + shorts -> Rf error
	; 1 short => Success, but not for me

	;========================================
	; Listen for command over RF
	;========================================
	call	RF_RX_ReceiveMsg

	movfw	RfRxReceiveResult
	sublw	.1
	btfss	STATUS, Z
	goto	RfError

	; 
	; 3) Does destination match us?
	; 
	; configure the address from which we read the crc
	movfw	RfRxMsgBuffer
	sublw	RF_RX_LOCAL_ADDR
	btfsc	STATUS, Z
	goto	_process_msg
	goto	_main_loop_cnt

RfError		; blink out the result
	movfw	RfRxReceiveResult
	movwf	temp
loop
	call	BlinkShort
	decfsz	temp, F
	goto	loop
	goto	_main_loop_cnt

_process_msg
	call	BlinkLong

_main_loop_cnt
	goto	_main


BlinkShort
	bsf		PORTC, 5
	bsf		PORTA, 4
	call 	Delay_100ms
	call 	Delay_100ms
	bcf		PORTC, 5
	bcf		PORTA, 4
	call 	Delay_100ms
	call 	Delay_100ms
	return
BlinkLong
	bsf		PORTC, 5
	bsf		PORTA, 4
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	bcf		PORTC, 5
	bcf		PORTA, 4
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	call 	Delay_100ms
	return


Delay_100ms
			;199993 cycles
	movlw	0x3E
	movwf	d1
	movlw	0x9D
	movwf	d2
Delay_100ms_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_100ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return

	end