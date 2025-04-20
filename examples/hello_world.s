    .org $0200
start:
    LDA #0

main_loop:
    JSR print_message
    ; HLT
    .byte $EF

print_message:
    LDX #0
print_loop:
    LDA message,X
    BEQ print_done
    STA $E000,X
    INX
    BNE print_loop
print_done:
    RTS

; --- data ---
message:
    .byte "Hello, World!", 0
