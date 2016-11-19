;--------------------------
; config.inc
;--------------------------

	list	p=16f690
#include    <p16f690.inc>

;**********************************************
; Memory config
;
; main.asm        : 11 bytes 0x20
; rf_protocol_rx  : 13 bytes 0x50

;**********************************************
; Port config:
; 
; RA0 - RX-rssi
; RA1 - RX-rssi-ref
; RA2 - TX-signal
; RA3 - <empty>
; RA4 - LED2
; RA5 - Relay out
; 
; RB4 - I2c DAT
; RB5 - <empty>
; RB6 - I2c SCK
; RB7 - Power 20mA
; 
; RC0 - <empty>
; RC1 - <empty>
; RC2 - <empty>
; RC3 - <empty>
; RC4 - <empty>
; RC5 - LED1
; RC6 - <empty>
; RC7 - <empty>
;**********************************************
#define CLOCKSPEED      		.8000000	; 8 MHz Osc
;#define CLOCKSPEED       		.4000000	; 4 MHz Osc
#define	OSCTUNE_VALUE			.0


;***************************************
; Values required by rf_protocol_rx.asm
;***************************************
#define	RF_RX_PORT_RSSI			PORTA, 0    ; C1IN+
#define	RF_RX_PORT_RSSI_REF		PORTA, 1    ; C12IN0-
#define	RF_RX_LOCAL_ADDR		.6			; local addr

