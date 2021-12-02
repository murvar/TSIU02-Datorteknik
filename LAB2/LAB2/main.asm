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
	.equ	time=30 ; Length of tone
	ldi		ZL,LOW(MESSAGE*2)
	ldi		ZH,HIGH(MESSAGE*2)
	ldi		r20,0B00010000 ; Set bit 4 on r20
	Out		DDRB,r20 ; Activate pin 4
	call	MORSE

MORSE:
	call	GET_CHAR
	cpi		r16,$20 ; Space sign
	breq	SPACE
	cpi		r16,$00 ; Char = 0? Exit
	breq	EXIT
	push	r16
	push	ZL
	push	ZH
	call	LOOKUP ; Translate from ASCII to morse
	call	SEND ; Char to beep
	pop		ZH
	pop		ZL
	pop		r16
NEXT:
	adiw	ZL,1 ; Move Z one step
	ldi		r17,(2*time) ; WAIT argument
	call	WAIT
	jmp		MORSE
GET_CHAR:
	lpm		r16,Z	; Get next char
	ret
SEND:
	cpi		r16,0	; Check if char done
	breq	RETURN
	call	GET_BIT ; Get next bit of char
	call	BEEP
	brcs	LONG	; Long if carry = 1
SHORT://Kort beep
	ldi		r17,time
	jmp		CONTINUE
LONG://L�ngt beep
	ldi		r17,(3*time)
CONTINUE:
	call	WAIT
	call	NOBEEP
	ldi		r17,time
	call	WAIT
	jmp		SEND
RETURN:
	ret

GET_BIT:
	rol		r16 ; r16x2, left shift
	ret

SPACE:
	ldi		r17,7*time
	call	NOBEEP
	call	WAIT
	jmp		NEXT

LOOKUP:
	ldi		ZL,LOW(BTAB<<1) ; Read table
	ldi		ZH,HIGH(BTAB<<1)
	subi	r16,$41 ; ASCII to table index
	add		ZL,r16 ; Z points to correct char in table
	lpm		r16,Z ; Read char
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

MESSAGE:.db		"VINAH VINAH VINAH", $00
BTAB:.db		$60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8