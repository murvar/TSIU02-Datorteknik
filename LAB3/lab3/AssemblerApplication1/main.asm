;
; AssemblerApplication1.asm
;
; Created: 12/8/2021 9:56:57 AM
; Author : Robin o Vincent
;

	.equ    FN_SET = $28      ;  4-bit mode, 2-line display, 5 x 8 font
	.equ    DISP_ON = $0C    ;  display on, cursor on, blink
	.equ    LCD_CLR = $01    ;  replace all characters with ASCII 'space'
	.equ    E_MODE =  $06   ; set cursor position
	.equ	E = 1
	.equ	RS = 0

	jmp		MAIN
	.org	OC1Aaddr
	jmp		AVBROTT

AVBROTT:
	push	r16
	in      r16,SREG
    push    r16
	call	TIME_TICK
	call	TIME_FORMAT
	call	LINE_PRINT
	pop		r16
	out		SREG, r16
	pop		r16

	reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.dseg
TIME:	.byte	6 ; reserverar sex bytes i sram
LINE:	.byte	16 
	.cseg

; Replace with your application code
MAIN:
	call	LCD_PORT_INIT
	call	LCD_INIT
	call	TIME_INIT
	call	TIMER1_INIT
	sei
IDLE:
    jmp		IDLE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCD_PORT_INIT:
    ldi		r16, 0b11111111
    out		DDRB, r16
    out		DDRD, r16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCD_INIT :
; --- turn backlight on
	call	WAIT
	call	BACKLIGHT_ON
; --- wait for LCD ready
	call	WAIT
;
; --- First initiate 4- bit mode
;
	ldi		r16 , $30
	call	LCD_WRITE4
	call	LCD_WRITE4
	call	LCD_WRITE4
	ldi		r16 , $20
	call	LCD_WRITE4
;
; --- Now configure display
;
; --- Function set : 4 - bit mode , 2 line , 5 x8 font
	ldi		r16 , FN_SET
	call	LCD_COMMAND
; --- Display on , cursor on , cursor blink
	ldi		r16 , DISP_ON
	call	LCD_COMMAND
; --- Clear display
	call	LCD_ERASE
; --- Entry mode : Increment cursor , no shift
	ldi		r16 , E_MODE
	call	LCD_COMMAND
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.equ SECOND_TICKS = 62500 - 1 ; @ 16/256 MHz
TIMER1_INIT :
	ldi r16 ,(1 << WGM12 )|(1 << CS12 ) ; CTC , prescale 256
	sts TCCR1B , r16
	ldi r16 , HIGH ( SECOND_TICKS )
	sts OCR1AH , r16
	ldi r16 , LOW ( SECOND_TICKS )
	sts OCR1AL , r16
	ldi r16 ,(1 << OCIE1A ) ; allow to interrupt
	sts TIMSK1 , r16
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIME_INIT:
	ldi		r17, 0
	ldi		r16, 5
	sts		TIME+0,r16
	ldi		r16, 4
	sts		TIME+1,r16
	ldi		r16, 9
	sts		TIME+2,r16
	ldi		r16, 5
	sts		TIME+3,r16
	ldi		r16, 3
	sts		TIME+4,r16
	ldi		r16, 2
	sts		TIME+5,r16
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCD_WRITE4:
	sbi		PORTB, E
	out		PORTD, r16
	NOP
	NOP
	NOP
	call	WAIT
	cbi		PORTB, E
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCD_WRITE8:
	call	LCD_WRITE4
	swap	r16
	call	LCD_WRITE4
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCD_ASCII:
	NOP
	sbi		PORTB, RS
	call	LCD_WRITE8
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCD_COMMAND:
	cbi		PORTB, RS
	call	LCD_WRITE8
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCD_HOME: // flytta pekare till $0
	ldi		r16 , $02
	call	LCD_COMMAND
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCD_ERASE:
	ldi		r16 , LCD_CLR
	call	LCD_COMMAND
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCD_PRINT:
	ld		r16,Z+    ; Get next char ld
	cpi		r16,$00 ; Char = 0? Exit
	breq	DONE
	call	LCD_ASCII
	jmp		LCD_PRINT
DONE:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LINE_PRINT:
	push	ZH
	push	ZL
	call	LCD_HOME
	ldi		ZH,HIGH(LINE)	; start of string
	ldi		ZL,LOW(LINE)
	call	LCD_PRINT		; print it
	pop		ZL
	pop		ZH
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIME_TICK:
	push	r16
	push	r17
	push	r18
	push	r19
	push	ZH
	push	ZL
	push	XH
	push	XL
	ldi		XH, HIGH(TIME)
	ldi		XL, LOW(TIME)
	ldi		ZH, HIGH(TIME_TABLE*2)
	ldi		ZL, LOW(TIME_TABLE*2)
TIME_TICK_LOOP:
	lpm		r17, Z+		; h?mtar max-v?rde i tabell FLASH 
	ld		r16, x		; h?mtar nuvarande tid
	inc		r16			; ?kar m 1
	cp		r16, r17	; j?mf?r tid m maxv?rde 
	brne	SAVE_TIME	; != k?r savetime
	clr		r16			; s?tt till 0
	st		x+, r16		; lagra 0an, ?ka
	jmp		TIME_TICK_LOOP	; loopa om

SAVE_TIME:
	st		x, r16
	cpi		r16, 4
	breq	SPECIAL_CASE
	jmp		RETURN

SPECIAL_CASE:
	ldi		r18, 4
	lds		r19, TIME+4
	cpse	r19, r18
	jmp		RETURN

	ldi		r18, 2
	lds		r19, TIME+5
	cpse	r19, r18
	jmp		RETURN

	call	TIME_ZERO
	
RETURN:
	pop		XL
	pop		XH
	pop		ZL
	pop		ZH
	pop		r19
	pop		r18
	pop		r17
	pop		r16
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIME_ZERO:
	push	r16
	push	r17
	push	XH
	push	XL
    ldi		r16,0
    ldi     r17,0
    ldi     XH,HIGH(TIME)
    ldi     XL,LOW(TIME)

LOOP_TIME_ZERO:
    cpi		r16,6
    breq	TIME_ZERO_FIN
    st		x+,r17
    inc		r16
    jmp		LOOP_TIME_ZERO
TIME_ZERO_FIN:
	pop		XL
	pop		XH
	pop		r17
	pop		r16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIME_FORMAT:
	push	XH
	push	XL
	push	YH
	push	YL
	push	ZH
	push	ZL
	push	r22
	push	r16
	ldi		XH, HIGH(TIME)
	ldi		XL, LOW(TIME)
	ldi		YH, HIGH(LINE)
	ldi		YL, LOW(LINE)
	ldi		ZH, HIGH(TIME_FORMAT_TABLE*2)
	ldi		ZL, LOW(TIME_FORMAT_TABLE*2)
	adiw	Y,7

LOOP_TIME_FORMAT:
	lpm		r22,z+
	cpi		r22,$3A
	breq	STORE
	cpi		r22,$00
	breq	FINISH
	ld		r16, X+
	add		r22, r16 ; hex to ascii

STORE:
	st		y, r22 
	sbiw	y,1
	jmp		LOOP_TIME_FORMAT
FINISH:
	adiw	y,9
	st		y, r22 
	pop		r16
	pop		r22
	pop		ZL
	pop		ZH
	pop		YL
	pop		YH
	pop		XL
	pop		XH
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WAIT:
    adiw    r24, 1
    brne    WAIT
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BACKLIGHT_ON:
	sbi		PORTB, 2
	sbi		DDRB, 2
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BACKLIGHT_OFF:
	cbi		PORTB, 2
	ret

TIME_TABLE:.db	10, 06, 10, 06, 10, 06

TIME_FORMAT_TABLE:.db	$30, $30, $3A, $30, $30, $3A, $30, $30, $00