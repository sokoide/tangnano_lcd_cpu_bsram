; JSR, RTS
; Program loaded and starts at 0x0200
    .org $0200

start:
    LDA #0
loop:
    JSR foo
; CVR: clear VRAM
    .byte $CF
; IFO: show registers and memory at $0000-$007F
    .byte $DF,$00,$00
; WVS: wait for 1 second
    .byte $FF, $3A
    JMP loop

foo:
    CLC
    ADC #1
    RTS