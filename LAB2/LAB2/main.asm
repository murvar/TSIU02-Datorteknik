;
; LAB2.asm
;
; Created: 2021-11-23 11:21:21
; Author : Vincent
;


start:
	ldi		r20, low(RAMEND)
	out		SPL, r20
	ldi		r20, high(RAMEND)
	out		SPH, r20

	.equ	time=20 ; Length of tone

	ldi		ZL,LOW(MESSAGE*2)
	ldi		ZH,HIGH(MESSAGE*2)
	ldi		r20,0B00010000
	Out		DDRB,r20
	call	MORSE

MORSE:
	call	GET_CHAR
	cpi		r16,$00 ; char = 0? Done
	breq	EXIT
	push	r16
	push	ZL
	push	ZH
	call	LOOKUP
	call	SEND
	pop		ZH
	pop		ZL
	pop		r16
	adiw	ZL,1
	ldi		r17,(2*time)
	call	WAIT
	jmp		MORSE
GET_CHAR:
	lpm		r16,Z
	ret
SEND:
	cpi		r16,0
	breq	RETURN
	call	GET_BIT
	call	BEEP
	brcs	LONG
SHORT://Kort beep
	ldi		r17,time
	jmp		CONTINUE
LONG://Långt beep
	ldi		r17,(3*time)
CONTINUE:
	call	WAIT
	call	NOBEEP
	ldi		r17,time
	call	WAIT
	jmp		SEND

GET_BIT:
	rol		r16 ; r16x2
	ret

	//pusha Z-pekaren
LOOKUP:
	ldi		ZL,LOW(BTAB<<1)
	ldi		ZH,HIGH(BTAB<<1)
	subi	r16,$41 
	add		ZL,r16
	lpm		r16,Z
	ret

RETURN:
	ret

EXIT:
	jmp		EXIT2

BEEP:
	sbi		PORTB,4
	ret

NOBEEP:
	cbi		PORTB,4
	ret

WAIT_LONG:
	adiw	r24,1
	brne	WAIT_LONG
	ret

WAIT:
	call	WAIT_LONG
	dec		r17
	brne	WAIT
	ret

EXIT2:

MESSAGE:.db		"DATORTTEKNIK", $00
BTAB:.db		$60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8
