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
	ldi		r16,$ff
	push	r16
	call	BEEP
	pop		r16
	call	WAIT
	push	r16
	call	NOBEEP
	pop		r16
	call	WAIT
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
	adiw	r28,63
D_3:
	adiw	r26,$3f
D_2:
	adiw	r24,$3f
D_1:
	dec		r28
	brne	D_1
	dec		r26
	brne	D_2
	dec		r24
	brne	D_3
	ret

WAIT:
    push r29
    ldi r29, $ff

WAIT2:
    push r30
    push r31
    ldi r30, $00
    ldi r31, $E0

WAIT3:
    adiw r30, 1
    brne WAIT3
    ; ~0.1 sekunder
    pop r31
    pop r30
    dec r29
    brne WAIT2
    pop r29
    ret