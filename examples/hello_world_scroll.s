    .org $0200

start:
    ; zero page ptr ($00, $01) = $E000 in little endian
    ; high byte ($E0)
    LDA #<$E000
    STA $00
    ; low byte ($00)
    LDA #>$E000
    STA $01

    ; init offsets
    LDA #0
    STA offset_lo
    STA offset_hi

main_loop:
    ; Wait for VSync
    .byte $FF
    .byte $00
    JSR print_message

    ; offset++
    INC offset_lo
    BNE skip_inc_hi
    INC offset_hi
skip_inc_hi:

    ; offset >= 1024 (0x0400) ?
    LDA offset_hi
    CMP #$04
    BCC continue
    ; reset
    LDA #0
    STA offset_lo
    STA offset_hi
continue:
    JMP main_loop

; -----------------------------------
; display: ($00),Y
; -----------------------------------
print_message:
    LDY #0
print_loop:
    ; LDA message,Y
    ; BEQ done

    ; Y = char index
    ; offset + $00/$01  → STA (indirect),Y
    ; $00/$01 = base ($E000) + offset
    LDA offset_lo
    CLC
    ADC #<$E000
    STA $00
    LDA offset_hi
    ADC #>$E000
    STA $01

    LDA message,Y
    BEQ done
    STA ($00),Y

    INY
    BNE print_loop
done:
    RTS

; -----------------------------------
; variables
; -----------------------------------
offset_lo:  .res 1
offset_hi:  .res 1

; -----------------------------------
; message
; -----------------------------------
message:
    .byte " Hello, World!", 0
