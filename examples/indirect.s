; Use of memory (data) and 2 different indirect modes
; (Indirect, X)
; (Indirect), Y
;
; Program loaded and starts at 0x0200
    .org $0200

start:
    ; ($04,$05) = $0070
    ; low byte of $0070
    LDA #<$0070
    STA $04
    ; high byte of $0070
    LDA #>$0070
    STA $05
    ; similarly, ($06, $07) = $0060
    LDA #<$0060
    STA $06
    LDA #>$0060
    STA $07
; Y = 2
    LDY #2
loop:
; Note:
; LDA absolute-addr, Y -> means A = *(absolute-addr+Y)
; A = *(data+Y)
; A ($0070) will be 3
    LDA data, Y
; Note:
; STA (indirect-addr), Y -> means *(addr-in-indirect-addr+Y) = A
; *($04,$05+Y) = A which means $0072 = 1
    LDA #1
    LDY #2
    STA ($04), Y
; STA (indirect-addr, X) -> means new-addr = indirect-addr+X,
; *(new-addr) = A which means $0060 = $A
    LDA #$A
    LDX #2
    STA ($04, X)
; LDA (indirect-addr), Y -> means A = *(addr-in-indirect-addr+Y)
; A = *($04,$05+Y) which means A = *$0072 = 1
    ; clear A
    LDA #0
    LDY #2
    LDA ($04), Y
; LDA (indirect-addr, X) -> means new-addr = indirect-addr+X,
; A = *(new-addr) which means A = *$0060 = $A
    ; clear A
    LDA #0
    LDX #2
    LDA ($04, X)
; ADC (Indirect), Y
    CLC;
    LDA #10;
    ; A = *$0072 + 10 = 11
    ADC ($04), Y
; ADC (Indirect, X)
    CLC;
    LDA #10;
    ; A = *$0060 + 10 = 20
    ADC ($04, X)
; SBC (Indirect), Y
    SEC;
    LDA #10;
    ; A = 10 - *$0072 = 9
    SBC ($04), Y
; SBC (Indirect, X)
    SEC;
    LDA #15;
    ; A = 15 - *$0060 = 5
    SBC ($04, X)
; AND (Indirect), Y
    LDA #10;
    ; A = 10 & *$0072
    AND ($04), Y
; AND (Indirect, X)
    LDA #15;
    ; A = 15 & *$0060
    AND ($04, X)
; EOR (Indirect), Y
    LDA #10;
    ; A = 10 xor *$0072
    EOR ($04), Y
; EOR (Indirect, X)
    LDA #15;
    ; A = 15 xor *$0060
    EOR ($04, X)
; ORA (Indirect), Y
    LDA #10;
    ; A = 10 or *$0072
    ORA ($04), Y
; ORA (Indirect, X)
    LDA #15;
    ; A = 15 or *$0060
    ORA ($04, X)
; CMP (Indirect), Y
    LDA #10;
    ; Test 10 - *$0072
    CMP ($04), Y
; CMP (Indirect, X)
    ; Test 10 - *$0072
    LDA #15;
    CMP ($04, X)

; CVR: clear VRAM
    .byte $CF
; IFO: show registers and memory at $0000-$007F
    .byte $DF,$00,$00
; WVS: wait for 1 second
    .byte $FF, $3A

; --- data ---
; count of data bytes, 1 byte
num_data:
    .byte 5
; 5 byte data
data:
    .byte 1, 2, 3, 4, 5
