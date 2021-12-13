;
; AssemblerApplication1.asm
;
; Created: 2021-12-13 08:36:56
; Author : Vincent
;

	.equ    FN_SET = $28      ;  4-bit mode, 2-line display, 5 x 8 font
	.equ    DISP_ON = $0F    ;  display on, cursor on, blink
	.equ    LCD_CLR = $01    ;  replace all characters with ASCII 'space'
	.equ    E_MODE =  $06   ; set cursor position
	.equ	E = 1
	.equ	RS = 0

	.dseg
LINE:	.byte	16 
	.cseg

; Replace with your application code
start:
	call	LCD_PORT_INIT
	call	LCD_INIT
    ;ldi		r16 , $9F
	;call	LCD_PRINT_HEX
	call	FUNKTIONSTEST_AD
    rjmp	stop

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

FUNKTIONSTEST_AD:
	call	ADC_READ8
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
	
STOP:
	jmp		STOP

ADC_READ8:
	ldi		r16,(1<<REFS0)|(1<<ADLAR)|0 ; AVCC/ADLAR/ADC0
	sts		ADMUX,r16 ; OBS! Inte IN/OUT
	ldi		r16,(1 << ADEN)|7 ; ADPS2..0 = 111 = 7
	sts		ADCSRA,r16
CONVERT:
	lds		r16, ADCSRA
	ori		r17, (1<<ADSC)
	sts		ADCSRA,r16 ; starta en omvandling
ADC_BUSY:
	lds		r16, ADCSRA
	sbrc	r16,ADSC ; om nollställd är vi klara
	rjmp	ADC_BUSY ; annars testa busy-biten igen
	lds		r16,ADCH ; En läsning av hög byte
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

