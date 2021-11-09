;
; LAB1.asm
;
; Created: 2021-11-08 16:20:51
; Author : Vincent
;


; Replace with your application code
start:
    ; r16-r19 free to use
	.def	num = r20 ; number 0-9 		.def = variabel?
	.def	key = r21 ; key pressed yes/no

	; set stack
	ldi		r16,HIGH(RAMEND) ; ldi = load immediate
	out		SPH,r16		; out to I/O location
	ldi		r16,LOW(RAMEND)
	out		SPL,r16

	call	INIT	; Kör INIT
	clr		num	    ; clear register
FOREVER:
	call	GET_KEY		; get keypress in boolean 'key'
LOOP:
	cpi		key,0
	breq	FOREVER		; until key
	out		PORTB,num	; print digit
	call	DELAY
	inc		num			; num++
	cpi		num,10		; num==10?
	brne	NOT_10		; no, so jump
	clr		num			; was 10
NOT_10:
	call	GET_KEY
	jmp		LOOP

	;
	; --- GET_KEY. Returns key != 0 if key pressed
GET_KEY:
	clr		key
	sbic	PINC,0		; <---- skip over if not pressed    sbic = Skip if Bit in I/O Register Cleared
	dec		key			; key=$FF
	ret

	;
	; --- Init. Pinnar on C in, B3-B0 out
INIT:
	clr		r16
	out		DDRC,r16	; <----
	ldi		r16,$0F
	out		DDRB,r16
	ret		 ; hoppa tillbaka

	;
	; --- DELAY. Wait a lot!
DELAY:
	ldi		r18,3
D_3:
	ldi		r17,0
D_2:
	ldi		r16,2
D_1:
	dec		r16
	brne	D_1
	;dec		r17
	;brne	D_2
	;dec		r18
	;brne	D_3
	ret
