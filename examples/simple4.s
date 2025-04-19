; Simple Example) draw 'A' on top-left
; Program loaded and starts at 0x0200
    .org $0200

start:
; load 'A' into A register
    LDA #$41
loop:
; store a value of A register at $01
    STA $01
; display 'A'
    STA $E000
; WVS: wait for 0.5 second
    .byte $FF, $1D
; IFO: show registers and memory at $0000-$007F
    .byte $DF,$00,$00
; WVS: wait for 0.5 second
    .byte $FF, $1D
; CLV: clear VRAM
    .byte $CF
; inclement A register
    CLC
    ADC #1
; if A == 'F', A='A'
    CMP #$46
    BNE loop
    LDA #$41
; loop
    JMP loop
