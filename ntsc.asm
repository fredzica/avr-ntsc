.INCLUDE "m328pdef.inc"
.INCLUDE "delay.asm"

.DEF wr0 = R16
.DEF wr1 = R17

;registros para funcoes de delay
.DEF reg_16bits_l = R24 
.DEF reg_16bits_h = R25
.DEF reg_delay_1 = R16
.DEF reg_delay_2 = R17

;variável global para contar as linhas
.DEF cont_line_l = R24
.DEF cont_line_h = R25

;pinos de saída de vídeo
.EQU video_pin = 0b00000010
.EQU sync_pin =  0b00000001

.CSEG
.ORG 0x0000


; ***** INTERRUPT VECTORS **********************************************
; retirado de m328pdef.inc
jmp init       ;reset handler
jmp retorno_interrupcao			; External Interrupt Request 0
jmp retorno_interrupcao			; External Interrupt Request 1
jmp retorno_interrupcao			; Pin Change Interrupt Request 0
jmp retorno_interrupcao			; Pin Change Interrupt Request 0
jmp retorno_interrupcao			; Pin Change Interrupt Request 1
jmp retorno_interrupcao			; Watchdog Time-out Interrupt
jmp timer2_compA_match_handler  ; Timer/Counter2 Compare Match A
jmp retorno_interrupcao			; Timer/Counter2 Compare Match B
jmp retorno_interrupcao			; Timer/Counter2 Overflow
jmp retorno_interrupcao			; Timer/Counter1 Capture Event
jmp retorno_interrupcao			; Timer/Counter1 Compare Match A
jmp retorno_interrupcao			; Timer/Counter1 Compare Match B
jmp retorno_interrupcao			; Timer/Counter1 Overflow
jmp retorno_interrupcao			; TimerCounter0 Compare Match A
jmp retorno_interrupcao			; TimerCounter0 Compare Match B
jmp retorno_interrupcao			; Timer/Couner0 Overflow
jmp retorno_interrupcao			; SPI Serial Transfer Complete
jmp retorno_interrupcao			; USART Rx Complete
jmp retorno_interrupcao			; USART, Data Register Empty
jmp retorno_interrupcao			; USART Tx Complete
jmp retorno_interrupcao			; ADC Conversion Complete
jmp retorno_interrupcao			; EEPROM Ready
jmp retorno_interrupcao			; Analog Comparator
jmp retorno_interrupcao			; Two-wire Serial Interface
jmp retorno_interrupcao			; Store Program Memory Read

retorno_interrupcao: 
	reti
; **********************************************************************

;serve para rodar o sync pulse e fazer a contagem de linhas
timer2_compA_match_handler:
	;o sync deve gastar 4,7us
	
	;se for igual a 262 zera.
	teste_262:
		cpi cont_line_h, high(262)
	brne fim
		cpi cont_line_l, low(262)
	brne fim
	
	reseta_cont:
		clr cont_line_l
		clr cont_line_h
	
	fim:
		ldi wr0, 0
		out PORTD, wr0
		adiw cont_line_l, 1
		
		delay_us 4 ;para tentar gerar o sync pulse de 4,7us
		
		reti

init:
	;inicialização da pilha na RAM
	ldi	wr0 , high(RAMEND)
	out SPH, wr0
	ldi wr0, low(RAMEND)
	out SPL, wr0
	
	;************************config de sleep mode***********************
	ldi wr0, 1
	out SMCR, wr0 ;configura sleep como idle mode
	;*******************************************************************
	
	;********config de interrupção de compare match A no timer 2********
	ldi wr0, 156	;62,4 us para cada interrupção acontecer
	sts OCR2A, wr0
	
	ldi wr0, (1 << WGM21) ;CTC mode
	sts TCCR2A, wr0
	
	;prescaler de 8
	ldi wr0, (1 << CS21)
	sts TCCR2B, wr0
	
	;ativa interrupção
	ldi wr0, (1 << OCIE2A)
	sts TIMSK2, wr0
	;*******************************************************************
	
	;coloca os dois pinos como saída
	ldi	wr0, video_pin | sync_pin
	out	DDRD, wr0
	
	;inicializa contador de linhas
	ldi cont_line_l, 0
	ldi cont_line_h, 0

	sei	;set global interrupt flag
	
imagem:	
	cpi cont_line_l, 248
	breq linha_248
	
	video:
		; coloca os 0.3V, que é o nível para mostrar cor preta
		ldi wr0, sync_pin
		out PORTD, wr0
		delay_us 8 ; delay de 8 é onde começa a desenhar a tela
		
		delay_us 22
		cpi cont_line_l, 225 ; só é visível até a linha 230!!!
		brne dormir
		
		ldi wr0, video_pin
		out PORTD, wr0
		
		ldi wr0, sync_pin
		out PORTD, wr0
		
		delay_us 5 ; os últimos 5us são front porch
		
	rjmp dormir
	
	; vertical sync
	; como mencionou o Sagar, basta fazer o vsync na linha 248
	linha_248: 
		ldi wr0, 0
		out PORTD, wr0
		delay_us 54 ;54, pois 4 já foram na interrupcao
		
		ldi wr0, sync_pin
		out PORTD, wr0
		delay_us 5
		
	dormir:
		sleep
	rjmp imagem
	
