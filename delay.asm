;Macros para delay. Consideram um clock de 20mhz.

;2.000.000 - 0,1s
;200.000 - 0,01s
;20.000 - 0,001s
;2000 - 0,0001s
;200 - 0,00001s
;20 - 0,000001s

;14 - 12(pushs e pops) = 2

;Macro que recebe parametro em us e faz o delay correspondente.
;Aceita parâmetro 1 <= @0 <= 65535.
;Tem o mérito de presevar todos os registros em que mexe na RAM e 
;depois voltar com os valores.

.MACRO delay_us
	;conserva os valores dos registradores na RAM
	push reg_16bits_l
	push reg_16bits_h
	push reg_delay_1

	;quantidade de iterações
	ldi R24, low(@0)
	ldi R25, high(@0)
	
	;gasta 20 ciclos em cada iteração
	outer_loop_1us:
		sbiw R24, 1
		breq resto_tempo ;completa 20ciclos se der overflow e determina se continua no loop
		
		ldi reg_delay_1, 5
		inner_loop_us:
			dec reg_delay_1
		brne inner_loop_us

	rjmp outer_loop_1us
	
	resto_tempo:
		nop
		nop
	
	;volta com os valores conservados para os registradores
	pop reg_delay_1
	pop reg_16bits_h
	pop reg_16bits_l
	
.ENDMACRO


;ao adicionar o loop mais externo:
;z = (20000+2+1+2)*(n-1) + 1+1+2+2+19994
;z = (20000+5)*(n-1) + 6+19994

;19994 - 16(pushs e pops) = 19978

;Macro que recebe parametro em ms e faz o delay correspondente.
;Aceita parâmetro 1 <= @0 <= 65535.
;Tem o mérito de presevar todos os registros em que mexe na RAM e 
;depois voltar com os valores.
.MACRO delay_ms
	;conserva os valores dos registradores na RAM
	push reg_16bits_l
	push reg_16bits_h
	push reg_delay_1
	push reg_delay_2

	;quantidade de iterações
	ldi R24, low(@0)
	ldi R25, high(@0)

	;gasta 20000 ciclos em cada iteração
	outer_loop_1:
		sbiw R24, 1
		breq resto_tempo ;completa 20000 ciclos se der overflow e determina se continua no loop
		
		; ============================= 
		;    delay loop generator 
		;     19995 cycles:
		; ----------------------------- 
		; delaying 19992 cycles:
				  ldi  reg_delay_1, $1C
		WGLOOP0:  ldi  reg_delay_2, $ED
		WGLOOP1:  dec  reg_delay_2
				  brne WGLOOP1
				  dec  reg_delay_1
				  brne WGLOOP0
		; ----------------------------- 
		; delaying 3 cycles:
				  nop
				  nop
				  nop
		; ============================= 

	rjmp outer_loop_1
		
	resto_tempo:
		; ============================= 
		;    delay loop generator 
		;     19978 cycles:
		; ----------------------------- 
		; delaying 19968 cycles:
				  ldi  reg_delay_1, $1A
		WGLOOP2:  ldi  reg_delay_2, $FF
		WGLOOP3:  dec  reg_delay_2
				  brne WGLOOP3
				  dec  reg_delay_1
				  brne WGLOOP2
		; ----------------------------- 
		; delaying 9 cycles:
				  ldi  reg_delay_1, $03
		WGLOOP4:  dec  reg_delay_1
				  brne WGLOOP4
		; ----------------------------- 
		; delaying 1 cycle:
				  nop
		; ============================= 
	
	;volta com os valores dos registradores que foram preservados no
	;início da macro
	pop reg_delay_2
	pop reg_delay_1
	pop reg_16bits_h
	pop reg_16bits_l
	
.ENDMACRO
