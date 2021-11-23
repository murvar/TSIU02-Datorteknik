;
; LAB2.asm
;
; Created: 2021-11-23 11:21:21
; Author : Vincent
;


start:
	;ldi		r16, low(RAMEND)
	;out		SPL, r16
	;ldi		r16, high(RAMEND)
	;out		SPH, r16
	.def	time = r16 ; Length of tone
	Out		DDRB,r16
	ldi		r16,16
	push	r16
	call	BEEP
	pop		r16
	call	DELAY
	push	r16
	call	NOBEEP
	pop		r16
	call	DELAY
	jmp		start


BEEP:
	sbi		PORTB,4
	ret

NOBEEP:
	cbi		PORTB,4
	ret

MESSAGE:
	.db "DATORTTEKNIK", $00

DELAY:
	ldi		r24,65535
D_3:
	ldi		r23,65535
D_2:
	ldi		r22,65535
D_1:
	dec		r24
	brne	D_1
	dec		r23
	brne	D_2
	dec		r22
	brne	D_3
	ret