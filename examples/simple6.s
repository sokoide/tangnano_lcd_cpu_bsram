; Use of memory (data) and 2 different indirect modes
; (Indirect, X)
; (Indirect), Y
;
; Program loaded and starts at 0x0200
    .org $0200

start:
; A = 0
    LDA #0
; X = 0
    LDX #0
; Y = 0
    LDY #0
loop:
; Note:
; LDA Addr, X -> (Indirect, X) which means A = *(Addr)+X
; LDA Addr, Y -> (Indirect), Y which means A = *(Addr+Y)
; A = *(data+Y)
    LDA data, Y
; Note:
; STA Addr, X -> (Indirect, X) which means *(Addr)+X = A
; STA Addr, Y -> (Indirect), Y which means *(Addr+Y) = A
; *($00+X) = A
    STA $00, X
; IFO: show registers and memory at $0000-$007F
    .byte $DF,$00,$00
; WVS: wait for 1 second
    .byte $FF, $3A
; CVR: clear VRAM
    .byte $CF
; X++
    INX
; if X != $20, goto y_check
    CPX #$20
    BNE y_check
; else X = 0
    LDX #0
y_check:
; Y++
    INY
; if Y != num_data goto loop
    CPY num_data
    BNE loop
; else Y = 0
    LDY #0
; loop
    JMP loop

; --- data ---
; count of data bytes, 1 byte
num_data:
        .byte 5
; 5 byte data
data:
        .byte $A, $B, $C, $D, $E
