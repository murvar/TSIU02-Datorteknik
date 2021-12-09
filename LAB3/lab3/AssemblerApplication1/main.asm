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
sei

.dseg
TIME:	.byte	6 ; reserverar sex bytes i sram
LINE:	.byte	16 
.cseg

; Replace with your application code
start:
	call	LCD_PORT_INIT
	call	LCD_INIT
	call	TIME_FORMAT
	call	LINE_PRINT
	call	TIME_TEST
    rjmp	start

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

LCD_WRITE4:
	sbi		PORTB, E
	out		PORTD, r16
	NOP
	NOP
	NOP
	cbi		PORTB, E
	call	WAIT
	ret

LCD_WRITE8:
	call	LCD_WRITE4
	swap	r16
	call	LCD_WRITE4
	swap	r16
	ret

LCD_ASCII:
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
	ld     r16,Z+    ; Get next char ld
	cpi		r16,$00 ; Char = 0? Exit
	breq	END
	call	LCD_ASCII
	jmp		LCD_PRINT
END:
	ret


LINE_PRINT:
	call	LCD_HOME
	ldi		ZH,HIGH(LINE)	; start of string
	ldi		ZL,LOW(LINE)
	call	LCD_PRINT		; print it
	ret

SAVE_TIME:
	st		x, r16
	ret

TIME_TEST:
	call	TIME_TICK
	jmp		TIME_TEST

TIME_TICK:
	ldi		XH, HIGH(TIME)
	ldi		XL, LOW(TIME)
	ld		r16, x

	;Ental Sekunder
	inc		r16
	cpi		r16, 10 ;Här ska vi istället ha ett variabelvärde för 6
	brne	SAVE_TIME
	clr		r16
	st		x+, r16

	;Tiotal Sekunder
	ld		r16, x
	inc		r16
	cpi		r16, 6 ;Här ska vi istället ha ett variabelvärde för 6
	brne	SAVE_TIME
	clr		r16
	st		x+, r16

	;Ental Minuter
	ld		r16, x
	inc		r16
	cpi		r16, 10 ;Här ska vi istället ha ett variabelvärde för 6
	brne	SAVE_TIME
	clr		r16
	st		x+, r16

	;Tiotal Minuter
	ld		r16, x
	inc		r16
	cpi		r16, 6 ;Här ska vi istället ha ett variabelvärde för 6
	brne	SAVE_TIME
	clr		r16
	st		x+, r16

	;Ental Timmar
	ld		r16, x
	inc		r16
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
	clr		r16
	st		x+, r16

	;Tiotal Timmar
	inc		r17
	mov		r16, r17
	cpi		r16, 3
	brne	SAVE_TIME
	clr		r17
	st		x+, r17
	ret

TIME_FORMAT:
	ldi		XH, HIGH(TIME)
	ldi		XL, LOW(TIME)
	ldi		r22, $30 
	ld		r16, X
	add		r22, r16
	adiw	x, 13
	st		x, r22 ; sätter ental sekund i LINE
	sbiw	x, 12
	ldi		r22, $30 
	ld		r16, X
	add		r22, r16
	adiw	x, 11
	st		x, r22 ; sätter tiotal sekund i LINE
	sbiw	x, 1
	ldi		r22, $3A
	st		x, r22 ; sätter ":"
	sbiw	x, 9
	ldi		r22, $30 
	ld		r16, X
	adiw	x, 8
	st		x, r22 ; sätter ental minut i LINE
	sbiw	x, 7
	ldi		r22, $30 
	ld		r16, X
	add		r22, r16
	adiw	x, 6
	st		x, r22 ; sätter tiotal sekund i LINE
	sbiw	x, 1
	ldi		r22, $3A
	st		x, r22 ; sätter ":"
	sbiw	x, 4
	ldi		r22, $30 
	ld		r16, X
	adiw	x, 3
	st		x, r22 ; sätter ental timme i LINE
	sbiw	x, 2
	ldi		r22, $30 
	ld		r16, X
	add		r22, r16
	adiw	x, 1
	st		x, r22 ; sätter tiotal timme i LINE
	adiw	x, 8
	ldi		r22, $00
	st		x, r22 ; sätter "null"

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
