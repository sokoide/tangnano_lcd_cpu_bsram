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
; load #1 into A register
    LDA #1
    STA $06
    STA $07
; load #0 into A register
    LDA #0
    STA $00
loop:
; load $00 into A
    LDA $00
; clear carry bit
    CLC
; add #1 with carry
    ADC #1
; store a value of A register at $00
    STA $00
    CLC
    ADC #1
    STA $01
    CLC
    ADC #1
    STA $02
    CLC
    ADC #1
    STA $03
    CLC
    ADC #1
    STA $04
    CLC
    ADC #1
    STA $05
    CLC
; rotate left
    LDA $06
    CLC
    ROL
    BCC rol_end
    ORA #$01
rol_end:
    STA $06
; rotate right
    LDA $07
    CLC
    ROR
    BCC ror_end
    ORA #$80
ror_end:
    STA $07
    INX
    INX
    INY
    INY
    INY

; IFO: show registers and memory at $7C00-$7C7F (shadow VRAM)
    .byte $DF,$00,$7C
; WVS: wait for 1 second
    .byte $FF, $3A
; CVR: clear VRAM
    .byte $CF
; loop
    JMP loop
