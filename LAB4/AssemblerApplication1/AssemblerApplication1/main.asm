;
; AssemblerApplication1.asm
;
; Created: 2021-12-13 08:36:56
; Author : Vincent
;

	.equ    FN_SET = $28      ;  4-bit mode, 2-line display, 5 x 8 font
	.equ    DISP_ON = $0F    ;  display on, cursor on, blink
	.equ    LCD_CLR = $01    ;  replace all characters with ASCII 'space'
	.equ    E_MODE =  $6   ; set cursor position
	.equ	E = 1
	.equ	RS = 0

	.dseg
LINE:	.byte	16+1
CUR_POS:.byte	1
	.cseg

; Replace with your application code
start:
	ldi		r18,1
	ldi		r16,0
	sts		CUR_POS,r16
	call	LCD_PORT_INIT
	call	LCD_INIT
	call	LINE_INIT
MAIN:
	call	KEY_READ
	call	LCD_COL
	;call	LCD_PRINT_HEX

    rjmp	MAIN

LCD_PORT_INIT:
    ldi		r16, 0b11111111
    out		DDRB, r16
    out		DDRD, r16
    ret

LCD_INIT:
; --- turn backlight on
	call	WAIT2
	call	BACKLIGHT_ON
; --- WAIT2 for LCD ready
	call	WAIT2
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

LINE_INIT:
	ldi		r16,0
	sts		LINE+0,r16
	sts		LINE+1,r16
	sts		LINE+2,r16
	sts		LINE+3,r16
	sts		LINE+4,r16
	sts		LINE+5,r16
	sts		LINE+6,r16
	sts		LINE+7,r16
	sts		LINE+8,r16
	sts		LINE+9,r16
	sts		LINE+10,r16
	sts		LINE+11,r16
	sts		LINE+12,r16
	sts		LINE+13,r16
	sts		LINE+14,r16
	sts		LINE+15,r16
	sts		LINE+16,r16
	ret

FUNKTIONSTEST_AD:
	call	ADC_READ8
	call	KEY
	call	LCD_ASCII
	jmp		FUNKTIONSTEST_AD

LCD_PRINT_HEX:
	call	NIB2HEX
NIB2HEX:
	swap	r16
	push	r16
	andi	r16 , $0F
	ori		r16 , $30
	cpi		r16 , ':'
	brlo	NOT_AF
	subi	r16 ,- $07
NOT_AF:
	call	LCD_ASCII
	pop		r16
	ret

ADC_READ8:
	ldi		r16,(1<<REFS0)|(1<<ADLAR)|0 ; AVCC/ADLAR/ADC0
	sts		ADMUX,r16 ; OBS! Inte IN/OUT
	ldi		r16,(1 << ADEN)|7 ; ADPS2..0 = 111 = 7
	sts		ADCSRA,r16
CONVERT:
	lds		r16,ADCSRA
	ori		r16,(1<<ADSC)
	sts		ADCSRA,r16 ; starta en omvandling
ADC_BUSY:
	lds		r16,ADCSRA
	sbrc	r16,ADSC ; om nollställd är vi klara
	jmp		ADC_BUSY ; annars testa busy-biten igen
	lds		r16,ADCH ; En läsning av hög byte
	ret

LCD_COL:
	cpi		r16,1
	breq	SELECT
	cpi		r16,2
	breq	LEFT
	cpi		r16,3
	breq	DOWN
	cpi		r16,4
	breq	UP
	cpi		r16,5
	breq	RIGHT
SELECT:
	cpi		r18,0
	breq	ON
OFF:
	ldi		r18,0
	call	BACKLIGHT_OFF
	ret
ON:
	ldi		r18,1
	call	BACKLIGHT_ON
	ret
	
LEFT:
	ldi		r16,1
	sts		CUR_POS,r16
	ldi		r16,$10
	call	LCD_COMMAND
	ret
DOWN:
	ldi		XH,HIGH(LINE)
	ldi		XL,LOW(LINE)
	lds		r16,CUR_POS
	add		XL,r16	; Move pointer to current column
	ld		r16,x	;
	cpi		r16,0
	breq	EMPTY_CHAR
	inc		r16
	st		x,r16 
	call	LCD_ASCII
	;ldi		r16,$10
	;call	LCD_COMMAND
	ret
EMPTY_CHAR:
	ldi		r16,65
	st		x,r16
	call	LCD_ASCII
	ret

UP:
	ret
RIGHT:
	ldi		r16,-1 ; Fungerar det här?
	sts		CUR_POS,r16
	ldi		r16 , $16
	call	LCD_COMMAND
	ret
	

KEY_READ :
	call	KEY
	tst		r16
	brne	KEY_READ ; old key still pressed
KEY_WAIT_FOR_PRESS :
	call	KEY
	tst		r16
	breq	KEY_WAIT_FOR_PRESS ; no key pressed
	; new key value available
	ret

KEY:
	call	ADC_READ8

	cpi		r16,13 ;om r16 mindre än 13? 5
	brlo	KEY_5

	cpi		r16,43 ;om r16 mindre än 43? 4
	brlo	KEY_4

	cpi		r16,82 ;om r16 mindre än 82? 3
	brlo	KEY_3

	cpi		r16,130 ;om r16 mindre än 130? 2
	brlo	KEY_2

	cpi		r16,207 ;om r16 mindre än 207? 1
	brlo	KEY_1
	; annars 0
KEY_0:
	ldi		r16,0
	ret
KEY_1:
	ldi		r16,1
	ret
KEY_2:
	ldi		r16,2
	ret
KEY_3:
	ldi		r16,3
	ret
KEY_4:
	ldi		r16,4
	ret
KEY_5:
	ldi		r16,5
	ret

LCD_WRITE4:
	sbi		PORTB, E
	out		PORTD, r16
	NOP
	NOP
	NOP
	call	WAIT2
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

LINE_PRINT:
	call	LCD_HOME
	ldi		ZH,HIGH(LINE)	; start of string
	ldi		ZL,LOW(LINE)
	call	LCD_PRINT_HEX	; print it
	ret

WAIT2:
    adiw    r24, 1
    brne    WAIT2
    ret

BACKLIGHT_ON:
	sbi		PORTB, 2
	sbi		DDRB, 2
	ret

BACKLIGHT_OFF:
	cbi		PORTB, 2
	ret

