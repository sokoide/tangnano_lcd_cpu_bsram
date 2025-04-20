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
