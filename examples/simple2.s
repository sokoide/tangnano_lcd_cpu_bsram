; Simple Example) draw 'A' and 'B' on top-left
;
; Used Instructions: same as simple.s
; LDA immediate (1byte)
; STA abosolute (2 bytes)
; $EF: HLT (custom instruction)
;
; Program loaded and starts at 0x0200
    .org $0200

start:
; load 'A'
    LDA #$41
; displaoy 'A'
    STA $E000
; load 'B'
    LDA #$42
; displaoy 'B'
    STA $E001
; HLT: stop CPU
    .byte $EF
