; Simple Example) draw 'A' on top-left
; Program loaded and starts at 0x0200
    .org $0200

start:
; load $41 ('A') into A register
    LDA #$41
; store a value of A register at $E000 (top-left corner of VRAM)
    STA $E000
; HLT: stop CPU
    .byte $EF
