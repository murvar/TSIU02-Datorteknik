;
; AssemblerApplication1.asm
;
; Created: 12/8/2021 9:56:57 AM
; Author : Robin o Vincent
;

	.equ    FN_SET = $28      ;  4-bit mode, 2-line display, 5 x 8 font
	.equ    DISP_ON = $0F    ;  display on, cursor on, blink
	.equ    LCD_CLR = $01    ;  replace all characters with ASCII 'space'
	.equ    E_MODE =  $06   ; set cursor position
	.equ	E = 1
	.equ	RS = 0

	jmp		MAIN
	.org	OC1Aaddr
TIMER1_INT:
	call	TIME_TICK
	call	TIME_FORMAT
	call	LINE_PRINT
	reti

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

LCD_PORT_INIT:
    ldi		r16, 0b11111111
    out		DDRB, r16
    out		DDRD, r16
    ret

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

LCD_WRITE4:
	sbi		PORTB, E
	out		PORTD, r16
	NOP
	NOP
	NOP
	call	WAIT
	cbi		PORTB, E
	ret

LCD_WRITE8:
	call	LCD_WRITE4
	swap	r16
	call	LCD_WRITE4
	ret

LCD_ASCII:
	NOP
	sbi		PORTB, RS
	call	LCD_WRITE8
	ret

LCD_COMMAND:
	cbi		PORTB, RS
	call	LCD_WRITE8
	ret

LCD_HOME: // flytta pekare till $0
	ldi		r16 , $02
	call	LCD_COMMAND
	ret

LCD_ERASE:
	ldi		r16 , LCD_CLR
	call	LCD_COMMAND
	ret

LCD_PRINT:
	ld		r16,Z+    ; Get next char ld
	cpi		r16,$00 ; Char = 0? Exit
	breq	DONE
	call	LCD_ASCII
	jmp		LCD_PRINT
DONE:
	ret


LINE_PRINT:
	call	LCD_HOME
	ldi		ZH,HIGH(LINE)	; start of string
	ldi		ZL,LOW(LINE)
	call	LCD_PRINT		; print it
	ret

TIME_TEST:
	call	TIME_TICK
	call	TIME_FORMAT
	call	LINE_PRINT
	jmp		TIME_TEST
	ret

SAVE_TIME:
	st		x, r16
	ret

TIME_TICK:
	ldi		XH, HIGH(TIME)
	ldi		XL, LOW(TIME)

	;Ental Sekunder
	ldi		r17,10
	call	INC_AND_COMPARE
	brne	SAVE_TIME
	call	CLEAR_AND_POSTINC

	;Tiotal Sekunder
	ldi		r17,6
	call	INC_AND_COMPARE
	brne	SAVE_TIME
	call	CLEAR_AND_POSTINC

	;Ental Minuter
	ldi		r17,10
	call	INC_AND_COMPARE
	brne	SAVE_TIME
	call	CLEAR_AND_POSTINC

	;Tiotal Minuter
	ldi		r17,6
	call	INC_AND_COMPARE
	brne	SAVE_TIME
	call	CLEAR_AND_POSTINC

	;Ental Timmar
	ld		r16, x
	inc		r16
	lds		r17, TIME+5
	cpi		r17, 2
	breq	SPECIAL_SINGULAR_HOUR
	brne	NORMAL_SINGULAR_HOUR
SPECIAL_SINGULAR_HOUR:
	cpi		r16, 4
	brne	SAVE_TIME
	jmp		CONTINUE_SINGULAR_HOUR
NORMAL_SINGULAR_HOUR:
	cpi		r16, 10 
	brne	SAVE_TIME
CONTINUE_SINGULAR_HOUR:
	call	CLEAR_AND_POSTINC

	;Tiotal Timmar
	ldi		r17,3
	call	INC_AND_COMPARE
	brne	SAVE_TIME
	call	CLEAR_AND_POSTINC
	ret

INC_AND_COMPARE:
	ld		r16, x
	inc		r16
	cp		r16, r17
	ret

CLEAR_AND_POSTINC:
	clr		r16
	st		x+, r16
	ret

TIME_FORMAT:
	ldi		XH, HIGH(TIME)
	ldi		XL, LOW(TIME)

	ldi		r22, $00
	sts		LINE+8, r22 ; sätter "null"

	call	HEX_TO_ASCII_AND_INC
	sts		LINE+7, r22 ; sätter ental sekund i LINE

	call	HEX_TO_ASCII_AND_INC
	sts		LINE+6, r22 ; sätter tiotal sekund i LINE

	ldi		r22, $3A
	sts		LINE+5, r22 ; sätter ":"

	call	HEX_TO_ASCII_AND_INC
	sts		LINE+4, r22 ; sätter ental minut i LINE

	call	HEX_TO_ASCII_AND_INC
	sts		LINE+3, r22 ; sätter tiotal sekund i LINE

	ldi		r22, $3A
	sts		LINE+2, r22 ; sätter ":"

	call	HEX_TO_ASCII_AND_INC
	sts		LINE+1, r22 ; sätter ental timme i LINE

	call	HEX_TO_ASCII_AND_INC
	sts		LINE, r22 ; sätter tiotal timme i LINE
	ret

HEX_TO_ASCII_AND_INC:
	ldi		r22, $30 
	ld		r16, X
	add		r22, r16
	adiw	x, 1
	ret

BLINK:
	call	TIME_TICK
	jmp		BLINK

AGAIN:
	call	BACKLIGHT_ON
	call	WAIT
	call	BACKLIGHT_OFF
	call	WAIT
	jmp		AGAIN

WAIT:
    adiw    r24, 1
    brne    WAIT
    ret

BACKLIGHT_ON:
	sbi		PORTB, 2
	sbi		DDRB, 2
	ret

BACKLIGHT_OFF:
	cbi		PORTB, 2
	ret
