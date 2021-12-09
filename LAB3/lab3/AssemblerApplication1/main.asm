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

.dseg
TIME:	.byte	6 ; reserverar sex bytes i sram
.cseg

; Replace with your application code
start:
	call	LCD_PORT_INIT
	call	LCD_INIT
	call	LINE_PRINT
	call	BLINK
    rjmp	start

LCD_PORT_INIT:
    ldi r16, 0b11111111
    out DDRB, r16
    out DDRD, r16
    ret

LCD_INIT :
; --- turn backlight on
	call WAIT
	call BACKLIGHT_ON
; --- wait for LCD ready
	call WAIT
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
	call LCD_ERASE
; --- Entry mode : Increment cursor , no shift
	ldi		r16 , E_MODE
	call	LCD_COMMAND
	ret

LCD_WRITE4:
	sbi PORTB, E
	out PORTD, r16
	NOP
	NOP
	NOP
	cbi PORTB, E
	call WAIT
	ret

LCD_WRITE8:
	call LCD_WRITE4
	swap r16
	call LCD_WRITE4
	ret

LCD_ASCII:
	sbi PORTB, RS
	call LCD_WRITE8
	ret

LCD_COMMAND:
	cbi PORTB, RS
	call LCD_WRITE8
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
	lpm     r16,Z    ; Get next char ld
	cpi		r16,$00 ; Char = 0? Exit
	breq	END
	adiw    ZL,1 ; Move Z one step
	call	LCD_ASCII
	jmp		LCD_PRINT
END:
	ret


LINE_PRINT:
	ldi		ZH,HIGH(LINE*2)	; start of string
	ldi		ZL,LOW(LINE*2)
	call	LCD_PRINT		; print it
	ret

;TIME_TICK:
;	adiw	r17, 1
;	brne	r17, 10
;	jmp		END
;	adiw	r17, 7
	

BLINK:
	jmp BLINK

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
	sbi PORTB, 2
	sbi DDRB, 2
	ret

BACKLIGHT_OFF:
	cbi PORTB, 2
	ret

LINE:.db     "5", $00