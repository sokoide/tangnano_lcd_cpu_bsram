; Used Instructions:
; JMP absolute (2 bytes)
; CLC implied (0 byte)
; ADC immediate (1 byte)
; SDA immediate (1byte)
; $DF: IFO (custom instruction, 2 bytes)
; $FF: WVS (custom instruction, 2 bytes)
; $CF: CVR (custom instruction)
;
; Program loaded and starts at 0x0200
    .org $0200

start:
; load #0 into A register
    LDA #0
; clear carry bit
    CLC
loop:
; add #1 with carry
    ADC #1
; store a value of A register at $00
    STA $00
; IFO: show registers and memory at $0000-$007F
    .byte $DF,$00,$00
; WVS: wait for 1 second
    .byte $FF, $3A
; CVR: clear VRAM
    .byte $CF
; loop
    JMP loop
