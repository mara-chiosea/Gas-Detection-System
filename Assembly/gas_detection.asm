.include "m32def.inc"
.equ rs = PA2
.equ e = PD6
.equ ctrl = PORTD
.equ ctrl2 = PORTA
 
; Definire digit1, digit2, digit3, și temp
.def digit1 = r18
.def digit2 = r19
.def digit3 = r21
.def temp = r23
 
jmp reset
jmp gata_conversia
 
reset:
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16
 
    ; Configurarea pinilor de date LCD ca ieșiri
    ldi r16, 0b11110000
    out DDRC, r16
 
    ; Configurarea pinilor de control LCD ca ieșiri
    ldi r16, 0b01000000
    out DDRD, r16
    ldi r16, 0b00000100
    out DDRA, r16
 
    ; Configurarea pinilor PD0 si PD1 ca ieșiri
    ldi r16, 0b00000011
    out DDRD, r16
 
    ; Inițializare display LCD
    call init_display
 
    ; Valoarea senzorului de gaz pe linia 1 LCD
    ldi r17, 0b10000000
    call set_ram
    ldi r17, 'G'
    call put_char
    ldi r17, 'a'
    call put_char
    ldi r17, 's'
    call put_char
    ldi r17, ' '
    call put_char
    ldi r17, 'V'
    call put_char
    ldi r17, 'a'
    call put_char
    ldi r17, 'l'
    call put_char
    ldi r17, 'u'
    call put_char
    ldi r17, 'e'
    call put_char
    ldi r17, ':'
    call put_char
 
    ; Seteazǎ dresa RAM la începutul liniei 2
    ldi r17, 0b11000000 ; 
    call set_ram
 
main:
    cli
 
    ; AREF referința, canal ADC7 (PA7)
    ldi r16, 0b01100111 ; ADLAR set to 1 for left alignment
    out ADMUX, r16
 
    ; activeazǎ ADC, seteazǎ prescalerul la fosc/64, start conversie
    ldi r16, 0b10111110
    out ADCSRA, r16
 
    ; activeazǎ auto-triggerul pe Timer 1
    in r16, SFIOR
    andi r16, 0b00011111
    ori r16, 0b10100000
    out SFIOR, r16
 
    ; Configureazǎ Timer 1: CTC mode, prescaler pe 1024
    ldi r16, 0b00001000
    out TCCR1B, r16
 
    ; Setez Timer 1 comparǎ valoarea A pt aprox 2 secunde/interval
    ldi r16, 0x3D
    out OCR1AH, r16
    ldi r16, 0x0A
    out OCR1AL, r16
 
    ; Setez Timer 1 comparat cu val B pt ADC trigger
    ldi r16, 0x3D
    out OCR1BH, r16
    ldi r16, 0x09
    out OCR1BL, r16
 
    ; activeazǎ întreruperi
    sei
 
    ; activeazǎ modul  ADC
    sbi ADCSRA, ADSC
 
    ; Start Timer 1
    in r16, TCCR1B
    andi r16, 0b11111101
    ori r16, 0b00000101
    out TCCR1B, r16
 
    ; Main loop
bucla:
    rjmp bucla
 
gata_conversia:
    in r20, SREG
 
    ; Citesc rezultat conversie ADC (aliniere la stângă)
    in r22, ADCH ; folosesc doar ADCH
 
    ; Reseteazǎ flag-ul întrerupere Timer 1
    in r16, TIFR
    ori r16, 0b00001000
    out TIFR, r16
 
    ; Setez adresa RAM
    ldi r17, 0b11000000 
    call set_ram
 
    ; Verificǎ dacǎ valoarea ADC este deasupra primului prag (150mV)
    cpi r22, 150  
    brlo threshold_1_not_met
 
    ; Porneste primul LED (PD0)
    sbi ctrl, 0
 
    ; Verifica daca valoarea ADC este peste al doilea prag (250mV)
    cpi r22, 250  
    brlo threshold_2_not_met
 
    ; Pornește al doilea LED (PD1)
    sbi ctrl, 1
    rjmp display_adc_value
 
threshold_2_not_met:
    ; Stinge al doilea LED (PD1)
    cbi ctrl, 1
    rjmp threshold_1_met 
 
threshold_1_met:
    rjmp display_adc_value
 
threshold_1_not_met:
    ; stinge primul LED (PD0)
    cbi ctrl, 0
 
display_adc_value:
    ; Converteste si pune pe display cei 3 digiti zecimali
    ldi r16, 0x00
    mov digit1, r16
    mov digit2, r16
    mov digit3, r16
    mov temp, r22 ;  
 
bucla1:
    inc digit3
    ldi r16, 0x0A
    cp digit3, r16
    brne bucla1_next
    clr digit3
    inc digit2
    ldi r16, 0x0A
    cp digit2, r16
    brne PC+3 ; 
    cp digit2, r16
    inc digit1
bucla1_next:
    dec temp
    breq display_digits
    rjmp bucla1
 
display_digits:
    //ldi r16,0x01
   //out portd,r16
            
    ldi r17, 0b11010000 
    call set_ram
 
    ; Display digit1
    mov r17, digit1
    ldi r16, 0x30 
    add r17, r16 
    call put_char
 
    ; Display digit2
    mov r17, digit2
    ldi r16, '0' 
    add r17, r16 
    call put_char
 
    ; Display digit3
    mov r17, digit3
    ldi r16, '0' 
    add r17, r16 
    call put_char
 
            end_adc:
    out SREG, r20
    reti
 
init_display:
    cbi ctrl2,rs
    ldi r16,0b00100000
    out PORTC,r16
    sbi ctrl,e
    call wait_48us 
    cbi ctrl,e
    ldi r16,0b00100000
    out PORTC,r16
    sbi ctrl,e
    call wait_48us
    cbi ctrl,e
    ldi r16,0b10000000
    out PORTC,r16
    sbi ctrl,e
    call wait_48us 
    cbi ctrl,e
    call wait_30ms
    ldi r16,0b00000000
    out PORTC,r16
    sbi ctrl,e
    call wait_48us 
    cbi ctrl,e
    ldi r16,0b11000000
    out PORTC,r16
    sbi ctrl,e
    call wait_48us 
    cbi ctrl,e
    call wait_30ms
    ldi r16,0b00000000
    out PORTC,r16
    sbi ctrl,e
    call wait_48us 
    cbi ctrl,e
    ldi r16,0b00010000
    out PORTC,r16
    sbi ctrl,e
    call wait_48us 
    cbi ctrl,e
    call wait_30ms
    ldi r16,0b00000000
    out PORTC,r16
    sbi ctrl,e
    call wait_48us 
    cbi ctrl,e
    ldi r16,0b00100000
    out PORTC,r16
    sbi ctrl,e
    call wait_48us 
    cbi ctrl,e
    call wait_30ms
    ret
 
set_ram:
    cbi ctrl2,rs
    mov r16,r17
    andi r16,0xF0
    out PORTC,r16
    sbi ctrl,e
    nop 
    nop 
    cbi ctrl,e
    mov r16,r17
    andi r16,0x0F
    swap r16
    out PORTC,r16
    sbi ctrl,e
    nop 
    nop 
    cbi ctrl,e
    call wait_48us 
    ret
 
put_char:
    sbi ctrl2,rs
    mov r16,r17
    andi r16,0xF0
    out PORTC,r16
    sbi ctrl,e
    nop 
    nop 
    cbi ctrl,e
    mov r16,r17
    andi r16,0x0F
    swap r16
    out PORTC,r16
    sbi ctrl,e
    nop 
    nop 
    cbi ctrl,e
    call wait_48us
    ret
 
wait_48us:
    ldi r16,0x00
    out TCNT0,r16
    ldi r16, 0x06 
    out OCR0,r16
    in r16,TCCR0
    andi r16,0b11111000
    ori r16,0b00000011
    out TCCR0,r16
wait:
    in r16,TIFR
    sbrs r16,OCF0
    rjmp wait
    in r16,TIFR
    ori r16,0b00000010
    out TIFR,r16
    in r16,TCCR0
    andi r16,0b11111000 ;se opreste timerul
    out TCCR0,r16
    ret
 
wait_30ms:
    ldi r16,0x00
    out TCNT0,r16
    ldi r16, 0xF0 
    out OCR0,r16
    in r16,TCCR0
    andi r16,0b11111000
    ori r16,0b00000101
    out TCCR0,r16
wait1:
    in r16,TIFR
    sbrs r16,OCF0
    rjmp wait1
    in r16,TIFR
    ori r16,0b00000010
    out TIFR,r16
    in r16,TCCR0
    andi r16,0b11111000 ;se opreste timerul
    out TCCR0,r16
  ret
