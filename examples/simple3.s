; Simple Example) draw 'A' on top-left
; Program loaded and starts at 0x0200
    .org $0200

start:
; load 'A' into A register
    LDA #$41
; store a value of A register at $01
    STA $01
loop:
; display 'A'
    STA $E000
; WVS: wait for 3 seconds
    .byte $FF, $AE
; IFO: show registers and memory at $0000-$007F
    .byte $DF,$00,$00
; WVS: wait for 3 seconds
    .byte $FF, $AE
; loop
    JMP loop
