;--------------------------
; config.inc
;--------------------------

	list	p=16f690
#include    <p16f690.inc>

;**********************************************
; Port config:
; 
; RA0 - SCK
; RA1 - DATA
; RA2 - <empty>
; RA3 - <empty>
; RA4 - <empty>
; RA5 - <empty>
; 
; RB4 - <empty>
; RB5 - <empty>
; RB6 - <empty>
; RB7 - <empty>
; 
; RC0 - <empty>
; RC1 - <empty>
; RC2 - <empty>
; RC3 - <empty>
; RC4 - <empty>
; RC5 - <empty>
; RC6 - <empty>
; RC7 - <empty>
;**********************************************
#define CLOCKSPEED      		.8000000	; 8 MHz Osc
;#define CLOCKSPEED       		.4000000	; 4 MHz Osc
#define	OSCTUNE_VALUE			.0


;***************************************
; Values required by sht15.asm
;***************************************
#define	SHT15_PWR			PORTC, 0
#define	SHT15_SCK			PORTC, 1
#define	SHT15_DATA			PORTC, 2

