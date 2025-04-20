    .org $0200
start:
    LDA #0

main_loop:
    JSR print_message
    ; HLT
    .byte $EF

print_message:
    LDX #0
    LDY #0
print_loop:
    LDA message,Y
    BEQ print_done
    STA $E000,X
    INY
    INX
    BNE print_loop
print_done:
    RTS

; --- data ---
message:
    .byte "Hello, World!", 0
