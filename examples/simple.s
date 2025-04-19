; Simple Example) draw 'A' on top-left
; Program loaded and starts at 0x0200
    .org $0200

start:
; load $41 ('A') into A register
    LDA #$41
; store a value of A register at $E000 (top-left corner of VRAM)
    STA $E000
; IFO: show registers and memory at $0000-$007F
    .byte $DF,$00,$00
; HLT: stop CPU
    .byte $EF
