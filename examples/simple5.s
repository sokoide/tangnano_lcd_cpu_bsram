; ADC, CMP, BNE
; Program loaded and starts at 0x0200
    .org $0200

start:
; load 'A' into A register
    LDA #$41
loop:
; CVR: clear VRAM
    .byte $CF
; store a value of A register at $01
    STA $01
; display register A's value
    STA $E000
; WVS: wait for 1 second
    .byte $FF, $3A
; IFO: show registers and memory at $0000-$007F
    .byte $DF,$00,$00
; WVS: wait for 1 second
    .byte $FF, $3A
; inclement A register
    CLC
    ADC #1
; if A != 'F' (#$46), goto loop
    CMP #$46
    BNE loop
; else A='A' (#$41)
    LDA #$41
; loop
    JMP loop
